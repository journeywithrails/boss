$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 14
# Invoice numbers, date, comments, and reference number
class InvoiceNumbersDateCommentTest < SageAccepTestCase
include AcceptanceTestSession
  fixtures :users
  fixtures :invoices

  def setup
    @basic_user = watir_session.with(:basic_user)
    @basic_user.logs_in
  end
  
  def teardown
    $debug=false
    @basic_user.teardown
  end

  def test_create_invoice_date_comment_reference
    b = @basic_user.b
    assert_difference 'Invoice.count', 1 do
      @basic_user.creates_new_invoice
      
      @user.populate(b.text_field(:id, 'invoice_date'), '11/25/2007')
      @user.populate(b.text_field(:id, 'invoice_reference'), 'ref #255')
      @user.populate(b.text_field(:id, 'invoice_description'),'test_create_invoice_date_comment_reference')
      
      @basic_user.enter_new_customer(
        :name => "Test 14 Customer"
      )    
      
      b.wait
      @basic_user.submits
    end

    invoice = Invoice.find(:first, :order => 'id DESC')
    assert_equal(Date.new(2007, 11, 25), invoice.date)
    assert_equal('ref #255', invoice.reference)
    assert_equal('test_create_invoice_date_comment_reference', invoice.description)    
  end
  
  def test_update_invoice_date_comment_reference
    b = @basic_user.b
    @basic_user.creates_new_invoice
    @basic_user.enter_new_customer(
        :name => "Test 14 Customer"
      )    
    @basic_user.sets_invoice(
      :date => 'Oct 9, 1977',
      :reference => '#412',
      :description => 'Original invoice description').
    and_submits

    invoice = Invoice.find(:first, :order => 'id DESC')
    
    assert_no_difference 'Invoice.count' do
      @basic_user.edits_invoice(invoice.id)
      @basic_user.populate(b.text_field(:id, 'invoice_date'),'10/09/2007')
      @basic_user.populate(b.text_field(:id, 'invoice_reference'),'ref #256')
      @basic_user.populate(b.text_field(:id, 'invoice_description'), 'test_update_invoice_date_comment_reference')
      b.wait
      @basic_user.submits
    end

    invoice.reload
    assert_equal(Date.new(2007, 10, 9), invoice.date)
    assert_equal('ref #256', invoice.reference)
    assert_equal('test_update_invoice_date_comment_reference', invoice.description)    
  end

  # The calendar control plugin does not come with tests, so exercise it
  # to see if it breaks.
  def test_exercise_calendar_control
    b = @basic_user.b
    
    # Select today and verify today's date
    @basic_user.edits_invoice(invoices(:invoice_with_date).id)
    b.image(:alt, 'Invoice Date').click
    b.wait
    assert b.div(:class, 'calendar_date_select').exists?
    b.div(:class, 'calendar_date_select').button('Today').click
    b.wait
    date = Date.parse(b.text_field(:id, 'invoice_date').value)
    assert_equal Date.today(), date
    
    # Verify the '<' and '>' buttons are working.
    b.image(:alt, 'Invoice Date').click
    b.wait
    assert b.div(:class, 'calendar_date_select').exists?
    b.div(:class, 'calendar_date_select').select_list(:class, 'year').select('2007')
    b.wait
    b.div(:class, 'calendar_date_select').select_list(:class, 'month').select('August')
    b.wait
    
    #RADAR: the next and previous buttons use onMouseDown events
    #so we must simulate the events instead of calling click().
    b.div(:class, 'calendar_date_select').button('>').fire_event('onMouseDown')
    b.div(:class, 'calendar_date_select').button('>').fire_event('onMouseUp')
    b.wait
    assert b.div(:class, 'calendar_date_select').select_list(:class, 'month').selected?('September')
    
    
    b.div(:class, 'calendar_date_select').button('<').fire_event('onMouseDown')
    b.div(:class, 'calendar_date_select').button('<').fire_event('onMouseUp')
    b.wait
    assert b.div(:class, 'calendar_date_select').select_list(:class, 'month').selected?('August')
    # selecting on :class => '' prevents picking a day from the previous or next month
    # note: this used to be cal.div(:class => '', :text => '1').click, which doesn't work in firewatir. easier to use an xpath than to fix the firewatir bug
    b.element_by_xpath("//div[@class='calendar_date_select']//div[not(@class) and contains(text(), '1')]").click
    b.wait
    
    #Get the date field and compare it with expected result.
    date = Date.parse(b.text_field(:id, 'invoice_date').value)
    assert_equal Date.new(2007, 8, 1), date


  end
  
  def test_change_date_with_calendar_control
    # $debug=true
    b = @basic_user.b
    assert_no_difference 'Invoice.count' do
      @basic_user.edits_invoice(invoices(:invoice_with_date).id)
      sleep 2 # firefox segfaults sometimes on next command. sleeping helps it not to do that. Bringing to front might help too...
      b.image(:alt, 'Invoice Date').click
      assert b.div(:class, 'calendar_date_select').exists?
      b.div(:class, 'calendar_date_select').select_list(:class, 'year').select('2000')
      b.div(:class, 'calendar_date_select').select_list(:class, 'month').select('February')
      # selecting on :class => '' prevents picking a day from the previous or next month
      # note: this used to be cal.div(:class => '', :text => '29').click, which doesn't work in firewatir. easier to use an xpath than to fix the firewatir bug
      b.element_by_xpath("//div[@class='calendar_date_select']//div[not(@class) and contains(text(), '29')]").click
      @basic_user.submits
    end
    
    invoice = Invoice.find(invoices(:invoice_with_date).id)
    assert_equal Date.new(2000, 2, 29), invoice.date, 'date should be Feb 29, 2000'
  end
  
  def test_create_invoice_custom_invoice_number
    b = @basic_user.b
    assert_difference 'Invoice.count', 1 do
      @basic_user.creates_new_invoice
      @basic_user.enter_new_customer(
        :name => "Test 14 Customer"
      )    
      @user.populate(b.text_field(:id, 'invoice_unique'), 'INV-Custom-number')
      @user.populate(b.text_field(:id, 'invoice_date'),'11/25/2007')
      @user.populate(b.text_field(:id, 'invoice_reference'),'ref #255')
      @user.populate(b.text_field(:id, 'invoice_description'),'test_create_invoice_date_comment_reference')
      b.wait
      @basic_user.submits
    end

    invoice = Invoice.find(:first, :order => 'id DESC')
    assert_equal('INV-Custom-number', invoice.unique)
    assert_equal(Date.new(2007, 11, 25), invoice.date)
    assert_equal('ref #255', invoice.reference)
    assert_equal('test_create_invoice_date_comment_reference', invoice.description)
  end
  
  def test_filter_by_invoice_number
    b = @basic_user.b
    assert_difference 'Invoice.count', 1 do
      @basic_user.creates_new_invoice
      @basic_user.enter_new_customer(
        :name => "Test 14 Customer"
      )    
      @basic_user.sets_invoice(
        :unique => 'Unique Custom number',
        :date => 'March 23, 2001',
        :reference => '#6119',
        :description => 'test_uniqueness_of_custom_invoice_number Invoice').
      and_submits
    end
    
    @basic_user.displays_invoice_list.
    and_filters_by_number('Unique Custom number')
    table = b.table(:id, 'line_items_table')
    trows = table.bodies[::WatirBrowser.first_item].rows
    assert_equal 1, trows.length
    # not only do we have to adjust indices by 1, but we have to use cells, because if we use the array notation on a row it is NOT off by one
    assert_equal 'Unique Custom number', trows[::WatirBrowser.item_index(1)].cells[::WatirBrowser.item_index(2)].text
   
  end

  # DSL tests
  def test_dsl_edit_generic_invoice_fields
    assert_difference 'Invoice.count' do
      @basic_user.creates_new_invoice
      @basic_user.enter_new_customer(
        :name => "Test 14 Customer"
      )    
      @basic_user.sets_invoice(:unique => 'INV-TEST', 
            :description => 'New Invoice', 
            :date => '4/28/2005', 
            :reference =>'44112').and_submits
    end    
  end
  
end