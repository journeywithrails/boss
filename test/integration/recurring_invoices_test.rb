require "#{File.dirname(__FILE__)}/../test_helper"

class RecurringInvoicesTest < ActionController::IntegrationTest
  
  fixtures :invoices
  fixtures :users
  fixtures :line_items
  fixtures :customers
  fixtures :invoice_files  
  fixtures :taxes
                      
  def setup
    stub_cas_logged_in users(:basic_user)
  end
  
  def teardown
    $log_on = false
  end

  # USER STORY: creating recurring invoices from regular invoices

  def test_creating_recurring_invoices_from_regular_invoice

    Time.stubs(:now).returns(Time.parse("2009-1-1 00:00:00+00:00").utc)

    @regular_invoice = invoices(:sent_invoice)
    @regular_invoice.update_attribute(:date, Date.new(2009,02,28) )
    get invoice_path(@regular_invoice)
    assert_response :success

    assert_difference 'Invoice.count', 1 do
      put create_recurring_invoice_url(@regular_invoice.id), :invoice=>{:frequency=>'monthly'}
    end

    @recurring_invoice = Invoice.find assigns(:recurring)[:id]

    assert_match /created successfully/, @response.body

    assert_equal Date.new(2009,03,31), @recurring_invoice.date
    assert_equal @recurring_invoice.customer_id, @regular_invoice.customer_id
    assert_equal @recurring_invoice.line_items.count, @regular_invoice.line_items.count
    assert_equal @recurring_invoice.line_items[0].attributes.except("id","invoice_id","updated_at"), @regular_invoice.line_items[0].attributes.except("id","invoice_id","updated_at")
  end

  def test_creating_recurring_invoices_from_regular_invoice_with_no_issue_date

    Time.stubs(:now).returns(Time.parse("2009-2-28 12:00:00+00:00").utc)

    @regular_invoice = invoices(:sent_invoice)
    @regular_invoice.update_attribute(:date, nil )

    put create_recurring_invoice_url(@regular_invoice.id), :invoice=>{:frequency=>'monthly'}

    @recurring_invoice = assigns(:recurring)
    assert_equal @recurring_invoice.date, Date.new(2009,3,31)
  end


  def test_should_list_recurring_invoices

    get recurring_invoices_url
    assert_response :success

    recurring = invoices(:recurring)

    assert_select "#invoice_#{recurring.id}" do
      assert_select "td.frequency", "monthly"
      assert_select "td a[href=/invoices/#{recurring.id}]"
      assert_select "td.date", "09/24/09"
      assert_select "td.customer a[href=/customers/1/edit]", recurring.customer.name
      assert_select "td.total_amount", "73.27"
      assert_select "a[href=/invoices/#{recurring.id}/generated]"
      assert_select "td.currency", recurring.currency
    end
    assert_select ".invoice", 2

    invoices(:recurring_sendable).update_attribute :created_by_id, 2
    get recurring_invoices_url
    assert_select ".invoice", 1, "should list only basic_user's invoices"
  end

  def test_should_delete_recurring_invoices
    recurring = invoices(:recurring)
    get invoice_url recurring
    assert_select "a", "Delete this invoice"

    assert_difference 'Invoice.count', -1 do
      delete invoice_url(recurring)
    end
  end

  def test_should_not_edit_recurring_invoices
    recurring = invoices(:recurring)
    get invoice_url recurring
    assert_select "a", { :count=>0, :text=>"Edit this invoice" }

    assert_not_equal 200, invoice_url(recurring)
  end

  def test_should_not_list_recurring_invoices_in_reports

    get 'report/invoice'
    assert_select "option", {:text=>"Recurring", :count=>0}, "There should not be no Recurring option in filters"

    get_report_data = lambda { get 'reports/invoice', {:limit=>10000}, {"Accept"=>"text/javascript"}; return @response.body }

    get_report_data.call
    assert @response.body !~ /(R|r)ecurring/

    before = get_report_data.call
    Invoice.recurring.each{|i| i.destroy}
    assert_equal before, get_report_data.call, "Recurring invoices should not affect reports"
  end

  def test_should_generate_recurring_invoice_on_specified_date

    invoices(:recurring_sendable).update_attribute :date, Date.new(2020,01,01) #far future to skip this one
    #alternative: Invoice.recurring.reject{|i| i.id == recurring.id}.each{|i| i.destroy }

    recurring = invoices(:recurring)

    recurring.update_attributes :date => Date.new(2010,07,25), :due_date => Date.new(2010,8,8)

    users(:basic_user).settings[:time_zone] = "US/Pacific"

    #Simulate three scheduled runs

    assert_no_difference 'Invoice.count', "invoice should not be generated yet" do
      Time.stubs(:now).returns( Time.parse("2010-07-24 12:00:00-07:00") )
      Invoice.process_recurring_invoices
    end

    # should be generated now
    assert_difference 'Invoice.count', +1, "invoice should be generated now" do
      Time.stubs(:now).returns( Time.parse("2010-07-25 04:00:00-07:00") )
      Invoice.process_recurring_invoices
    end

    assert_no_difference 'Invoice.count', "invoice should not be generated twice" do
      Time.stubs(:now).returns( Time.parse("2010-07-25 12:00:00-07:00") )
      Invoice.process_recurring_invoices
    end

    #assert_equal Time.parse("2010-07-25 04:00:00-07:00"), invoice.created_at
    #assert_equal invoice.created_at_before_type_cast, "2010-07-25 11:00:00"
  end



  # User story: setting different schedules
  def test_creating_recurring_invoices_with_weekly_frequency

    Time.stubs(:now).returns(Time.parse("2009-1-1 00:00:00+00:00").utc)

    @regular_invoice = invoices(:sent_invoice)
    @regular_invoice.update_attribute(:date, Date.new(2009,02,28) )
    get invoice_path(@regular_invoice)

    assert_difference 'Invoice.count', 1 do
      put create_recurring_invoice_url(@regular_invoice.id), :invoice=>{:frequency=>'weekly'}
    end

    @recurring_invoice = Invoice.find assigns(:recurring)[:id]

    assert_equal Date.new(2009,03,07), @recurring_invoice.date
    assert_equal "weekly", @recurring_invoice.schedule.frequency
  end

  # User story: sending invoices automatically
  def test_incomplete_invoice_is_not_made_sendable_recurring
    draft = invoices(:draft_invoice) #Given the user has an invoice

    draft.line_items.delete_all #and the invoice has no line items

    assert_no_difference 'Invoice.count', "should not create recurring invoice" do

    #When the user selects "Send automatically"
    #and the user enters some recipients
    #and the user clicks "create recurring"
    put create_recurring_invoice_url(draft), :id=>draft.id, :invoice=>{      
        :frequency          => 'weekly',
        :send_recipients    => "bob@example.com, simon+garfunkel@example.com"
      }
    end

    assert_response :success
    assert_select ".errorExplanation" do
      assert_select "li", /(L|l)ine items/, "should display error message"
    end
  end

  def test_complete_invoice_is_made_sendable_recurring
    #Given the user has a invoice draft
    #and the invoice has all fields filled
    #When the user selects send this invoice
    #and the user clicks Create recurring
    #Then the user should see This invoice cannot be sent because: It has no line items. Please edit the invoice and add one or more line items.
    #and the invoice should not be recurring
    draft = invoices(:sent_invoice) #Given the user has an invoice

    assert_difference 'Invoice.count', 1 , "should not create recurring invoice" do
    #When the user selects "Send automatically"
    #and the user enters some recipients
    #and the user clicks "create recurring"
    put create_recurring_invoice_url(draft), :id=>draft.id, :invoice=>{      
        :frequency          => 'weekly',
        :send_recipients    => "bob@example.com, simon+garfunkel@example.com"
      }
    end
    recurring = Invoice.find(:first, :order => "id desc")
    assert_equal "bob@example.com, simon+garfunkel@example.com", recurring.send_recipients
  end

  def scenario_sendable_recurring_is_sent_automatically
    recurring = invoices(:recurring_sendable) #Given the user has a sendable recurring invoice
    invoices(:recurring_sendable).update_attribute :date, Date.new(2009,10,17) #and invoice's next issue date is Oct 17th 2009
    Time.stubs(:now).returns( Time.parse("2009-10-17 16:00:00-00:00") ) #and today is Oct 17th 2009

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    Invoice.process_recurring_invoices #When the recurring invoices scheduled processing is triggered
    #then an email should be sent

    assert_equal 1, ActionMailer::Base.deliveries.count
  end


  # USER STORY 4: listing generated invoices

  def test_should_lists_generated_invoices

    recurring = invoices(:recurring)
    
    generated_invoice = recurring.generated_invoices.first
    
    get generated_invoice_url(recurring)

    assert_select "#invoice_#{generated_invoice.id}" do
      assert_select "td.customer a[href=/customers/1/edit]", generated_invoice.customer.name
      assert_select "td.date", "06/10/09"
      assert_select "td.total_amount", "0.0"
      assert_select "td.currency", generated_invoice.currency
      assert_select "td a[href=/invoices/#{generated_invoice.id}]"
    end
  end
  
end
