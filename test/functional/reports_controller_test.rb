require File.dirname(__FILE__) + '/../test_helper'
class ReportsControllerTest < Test::Unit::TestCase
  fixtures :payments
  fixtures :invoices
  fixtures :users
  
  def setup
    @controller = ReportsController.new
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # sign on with the bookkeeper user for the bookkeeping client report tests    
    if self.method_name == "test_should_show_bookkeeping_client_report" or
       self.method_name == "test_should_load_bookkeeping_client_report_as_json" or
       self.method_name == "test_should_filter_bookkeeping_client_report"
      @user = users(:bookkeeper_user)
      login_as :bookkeeper_user
    else
      @user = users(:basic_user) 
      login_as :basic_user
    end
    
    #FIXME: this is SLOW!!!! Adds about a second to every test
  end
  
  def test_should_show_payment_report
    get :show, :id => 'payment'
    assert_response :success
    assert_template "reports/payment"
  end

  def test_should_show_invoice_report
    get :show, :id => 'invoice'
    assert_response :success
    assert_template "reports/invoice"
  end

  def test_should_load_payment_report_as_json
    @user = users(:customer_list_user)
    login_as :customer_list_user

    xhr :get, :show, :id => 'payment', :limit => '10'
    assert_response :success

    assert_not_nil assigns(:filters)
    assert_match /"amount": "200.00"/, @response.body
  end

  def test_should_load_invoice_report_as_json
    xhr :get, :show, :id => 'invoice', :limit => '10'
    assert_response :success

    assert_not_nil assigns(:filters)
    assert_match /"total": 23/, @response.body
  end

  def test_should_show_bookkeeping_client_report
    get :show, :id => 'invoice', :bookkeeping_client_id => '13'
    assert_response :success
    assert_template "reports/invoice"
    assert @response.body.include?("customer 2 for user has bookkeeping contract")
  end

  def test_should_show_bookkeeping_client_report
    get :print, :id => 'invoice', :bookkeeping_client_id => '13'
    assert_response :success
    assert_template "reports/invoice_print"
    assert @response.body.include?("customer 2 for user has bookkeeping contract")
  end

  def test_should_load_bookkeeping_client_report_as_json
    xhr :get, :show, :id => 'invoice', :bookkeeping_client_id => '13', :limit => '10'
    assert_response :success

    assert_not_nil assigns(:filters)
    assert_match /"total": 2/, @response.body
    assert_match /"total_amount": "30.00"/, @response.body # \"total_amount\": \"30.00\"
  end

  def test_should_filter_invoice_report_by_statuses
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => 'invoice', :filters=>{:meta_status => Invoice::META_STATUS_DRAFT}
    assert_response :success
    assert_equal Invoice::META_STATUS_DRAFT, assigns(:filters).meta_status
  end

  def test_should_filter_inovice_reports_by_currency
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => 'invoice', :filters=>{:currency => "ZAR"}
    assert_response :success
    assert_equal "ZAR", assigns(:filters).currency
  end

  def test_should_filter_invoice_reports_by_first_currency_if_no_previous_filter_history
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :show, :id => 'invoice'
    assert_response :success
    assert_equal "CAD", assigns(:filters).currency
  end
  #
  def test_should_filter_payment_reports_by_currency
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => 'payment', :filters=>{:currency => "ZAR"}
    assert_response :success
    assert_equal "ZAR", assigns(:filters).currency
  end

  def test_should_filter_payment_reports_by_first_currency_if_no_previous_filter_history
    @user = users(:user_for_payments)
    login_as :user_for_payments

    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :show, :id => 'payment'
    assert_response :success
    assert_equal "USD", assigns(:filters).currency
  end

  def test_should_filter_bookkeeping_client_report
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :show, :id => 'invoice', :bookkeeping_client_id => '13'
    assert_response :success
    as_ruby = eval(@response.body.gsub(':', '=>').gsub('null', 'nil'))
    json_total_amount = BigDecimal.new(as_ruby['summary']['total_amount'].to_s)
    json_total_count = BigDecimal.new(as_ruby['total'].to_s)
    assert_equal json_total_amount, BigDecimal.new("30.00"),
      "total_amount in json summary #{json_total_amount.to_s} did not equal actual sum of total_amount 30.00"
    assert_equal json_total_count, BigDecimal.new("2"),
      "filtered count in json summary #{json_total_count.to_s} did not equal actual count 2"

    # filter the report for one customer
    xhr :get, :show, :id => 'invoice', :bookkeeping_client_id => '13',
      :filters=>{:customers => "56" }
    assert_response :success
    as_ruby = eval(@response.body.gsub(':', '=>').gsub('null', 'nil'))

    json_total_amount = BigDecimal.new(as_ruby['summary']['total_amount'].to_s)
    json_total_count = BigDecimal.new(as_ruby['total'].to_s)
    assert_equal json_total_amount, BigDecimal.new("10.00"),
      "filtered total_amount in json summary #{json_total_amount} did not equal actual sum of total_amount 10.00"
    assert_equal json_total_count, BigDecimal.new("1"),
      "filtered count in json summary #{json_total_count} did not equal actual count 1"
  end

  def test_grid_filter_should_clear_search_filter_settings_for_invoices
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => 'invoice', :filters=>{:customers => "test_customer", :fromdate => "2007-01-11", :todate=> "2008-01-11", :clear => "Clear"}
    assert_response :success
    assert_template "reports/invoice"
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal nil, assigns(:filters).customers
    assert_equal nil, assigns(:filters).fromdate
    assert_equal nil, assigns(:filters).todate
  end

  def test_grid_filter_should_clear_search_filter_settings_for_payments
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => 'payment', :filters=>{:customers => "test_customer", :fromdate => "2007-01-11", :todate=> "2008-01-11", :clear => "Clear"}
    assert_response :success
    assert_template "reports/payment"
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal nil, assigns(:filters).customers
    assert_equal nil, assigns(:filters).fromdate
    assert_equal nil, assigns(:filters).todate
  end

  def test_should_remember_search_filter_settings
    get :show, :id => 'invoice', :filters=>{:unique=>"2", :something => 'blah'}
    assert_response :success
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal "2", assigns(:filters).unique
    assert_equal "blah", assigns(:filters).something
  end

  def test_should_summarize_invoice_amounts
    @user.invoices.each{|i| i.save(false)} # this ugliness because fixtures do not have valid summary fields!
    
    xhr :get, :show, :id => 'invoice', :limit => '10'
    assert_response :success


    assert_not_nil assigns(:filters)

    as_ruby = eval(@response.body.gsub(':', '=>').gsub('null', 'nil'))

    selected_invoices = @user.invoices.reject(&:quote?).reject(&:recurring?)

    [ :total_amount, :tax_1_amount, :tax_2_amount, :discount_amount, :paid_amount, :owing_amount ].each do |field|

      expected = selected_invoices.inject(BigDecimal('0')){|sum, i| sum += i.send(field) }.to_f
      actual = BigDecimal.new(as_ruby['summary'][field.to_s].gsub(',','').to_s).to_f
      assert_equal expected, actual, "#{field} in json summary did not equal actual sum of #{field}"
      
    end

    expected = selected_invoices.inject(BigDecimal('0')){|sum, i| sum += i.line_items_total }.to_f
    actual = BigDecimal.new(as_ruby['summary']['subtotal_amount'].gsub(',','').to_s).to_f
    assert_equal expected, actual, "subtotal_amount in json summary did not equal actual sum of line items"

    assert_match /"total": 23/, @response.body
  end

  def test_should_summarize_payment_amount
    @user = users(:customer_list_user)
    @user.payments.each{|p| p.save(false)}
    login_as :customer_list_user

    xhr :get, :show, :id => 'payment', :limit => '10'
    assert_response :success

    assert_not_nil assigns(:filters)

    as_ruby = eval(@response.body.gsub(':', '=>').gsub('null', 'nil'))

    assert_equal BigDecimal.new(as_ruby['summary']['amount'].gsub(',','').to_s),
      @user.payments.inject(BigDecimal('0')){|sum, p| sum += p.amount },
      "paid in json summary did not equal actual sum of total_amount"

    assert_match /"amount": "200.00"/, @response.body
  end

  def test_should_summarize_payment_amount
    @user = users(:customer_list_user)
    @user.payments.each{|p| p.save(false)}
    login_as :customer_list_user

    xhr :get, :show, :id => 'payment', :limit => '10'
    assert_response :success

    assert_not_nil assigns(:filters)

    as_ruby = eval(@response.body.gsub(':', '=>').gsub('null', 'nil'))

    assert_equal BigDecimal.new(as_ruby['summary']['amount'].gsub(',','').to_s),
      @user.payments.inject(BigDecimal('0')){|sum, p| sum += p.amount },
      "paid in json summary did not equal actual sum of total_amount"

    assert_match /"amount": "200.00"/, @response.body
  end

  def test_printed_invoice_report
    get :print, :id => 'invoice'
    assert_response :success

    assert @response.body.include?("Invoices Report for basic_user_profile_name (#{assigns(:invoices).size} invoices)")
    assert @response.body.include?("Paid")
    assert @response.body.include?("customer with invoice for every status")
  end

  def test_printed_payment_report
    @user = users(:customer_list_user)
    login_as :customer_list_user

    get :print, :id => 'payment'
    assert_response :success
    assert @response.body.include?("Payments Report for #{users(:customer_list_user).sage_username} (4 payments)")
    assert @response.body.include?("Total")
  end

  def test_csv_invoice_generation
    get :show, :id => 'invoice', :format => 'csv'
    assert_response :success
    assert @response.body.include?("Customer")
    assert @response.body.include?("Grand totals:")
    assert @response.body.include?("Paid")
    assert @response.body.include?("customer with invoice for every status")
    assert @response.headers["type"].include?("text/csv")
  end

  def test_csv_payment_generation
    get :show, :id => 'payment', :format => 'csv'
    assert_response :success
    assert @response.body.include?("Customer")
    assert @response.body.include?("Grand totals:")
    assert @response.headers["type"].include?("text/csv")
  end

  def test_quotes_should_not_be_listed
    get :show, :id => 'invoice'
    assert_select "select#filters_meta_status" do
      assert_select "option", {:text => /(q|Q)uote/, :count => 0}
    end
  end
  
end
