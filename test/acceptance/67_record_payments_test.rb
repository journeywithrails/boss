$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'

# Test cases for User Story 67:
# Users can record payments offline.
#
# Description: As a user, I want to record payments which I received from my customers
# so that I know which invoices have already been paid and which ones I still need to collect money.

class RecordPaymentsTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers
  
  def setup
  end
  
  def teardown
    @user.teardown
  end

  #These cases are implicit inside the test
  #3. Users can specify the payment amount
  #4. Users can specify the payment date
  #5. Users can enter notes, which could be used to store the credit card number, cheque number etc
  def test_record_payment_and_verify_status_acknowledged
    @user = watir_session.with(:user_for_payments)
    @user.logs_in

  	invoice_to_pay = invoices(:partially_paid_invoice)
	# Status is acknowledged at the beginning
	i = Invoice.find(invoices(:partially_paid_invoice).id)
	assert_equal 'acknowledged', i.status
	
	current_owing = 0.0
	current_payment = 0.0
	
	#1. Users can record payment against a specific invoice	
	@user.displays_invoice_list()
	@user.shows_invoice(invoice_to_pay.id)

	@user.creates_new_payment_for_invoice(invoice_to_pay.id)


	current_owing = invoice_to_pay.amount_owing
  #(@user.b.span(:id, "invoice_amount_owing").text).to_f

	@user.b.select_list(:id, "payment_pay_type").select("cheque")
	current_payment = 100.99
	@user.populate(@user.b.text_field(:id, "payment_amount"),(current_payment.to_s))
	@user.populate(@user.b.text_field(:id, "payment_date"),("11/28/2007"))
	@user.populate(@user.b.text_field(:id, "payment_description"),("This is the first partial payment"))
	assert_difference('Payment.count') do
		@user.submits
	end

    
	#2. Users can specify the type of payment
	# Make another payment with a different type of payment
	@user.b.link(:name, "record_payment").click
	current_owing -= current_payment

	assert_equal(format_amount(current_owing).to_s, @user.b.span(:id, "invoice_amount_owing").text)

	@user.b.select_list(:id, "payment_pay_type").select("cash")
	current_payment = 500.95
	@user.populate(@user.b.text_field(:id, "payment_amount"),(current_payment.to_s))
	@user.populate(@user.b.text_field(:id, "payment_date"),("11/28/2007"))
	@user.populate(@user.b.text_field(:id, "payment_description"),("This the second partial payment"))
	assert_difference('Payment.count') do
		@user.submits
	end
	
	# The third payments pays the rest being owed
	@user.b.link(:text, "Record a payment").click
	current_owing -= current_payment
	assert_equal(format_amount(current_owing).to_s, @user.b.span(:id, "invoice_amount_owing").text)
	
	@user.b.select_list(:id, "payment_pay_type").select("credit card")
	current_payment = 399.05
	@user.populate(@user.b.text_field(:id, "payment_amount"),(current_payment.to_s))
	@user.populate(@user.b.text_field(:id, "payment_date"),("11/28/2007"))
	@user.populate(@user.b.text_field(:id, "payment_description"),("This the third partial payment"))
	assert_difference('Payment.count') do
		@user.submits
	end
	
	#6. Once the payment has been recorded, the invoice is now marked as paid
	i = Invoice.find(invoices(:partially_paid_invoice).id)
	assert_equal 'paid', i.status
	
	# Verify owed is now 0.0	
	@user.b.link(:text, "Record a payment").click
  
	current_owing -= current_payment
	assert @user.b.row(:id, "preview_owing_row").span(:id, "invoice_total").innerText.include?(format_amount(current_owing).to_s)
  end

  # The status must change to paid once the Invoice is 
  # fully paid
  def test_record_payment_and_verify_status_draft
  	@user = watir_session.with(:basic_user)
    @user.logs_in

  	@user.displays_invoice_list()
  	i = Invoice.find(invoices(:draft_invoice).id)
  	assert_equal 'draft', i.status
	
  	@user.edits_invoice(invoices(:draft_invoice).id)
    #@user.sets_invoice_info(:unique => "Inv-0001")
    @user.b.wait
    @user.select_list(:id, "invoice_customer_id").option(:text, "Customer with Contacts").select
    @user.b.wait
    #@user.sets_invoice_contact(:first_name => "My Contact First Name",
	#	:last_name => "My Contact Last Name")
    @user.populate(@user.text_field(:id, "invoice_discount_value"),"50.00")
    @user.select_list(:id, "invoice_discount_type").option(:text, "amount").select

    assert_equal 2, @user.adds_line_item(:unit => "Item A",
					:description => "Description for Item A",
					:quantity => "10.0",
					:price => "5.50")
		
    # Submit and verify
	assert_difference 'LineItem.count', 2 do
    	@user.submits        
    end

  @user.span(:id, "mark_sent").links[1].click
  @user.wait()

  @user.link(:name, 'record_payment').click
  @user.wait
  
    assert_difference 'Payment.count' do
      assert_difference 'PayApplication.count' do
        #Enter payment information.
        e = @user.select_list(:id, 'payment_pay_type')
        assert e.exists?, 'Should have payment field payment_pay_type'
        e.select('credit card')
        e = @user.text_field(:id, 'payment_amount')
        assert e.exists?, 'field payment_amount should exist'
        @user.populate(e, (5.00).to_s)
        e = @user.text_field(:id, 'payment_date')
        assert e.exists?, 'field payment_date should exist'
        @user.populate(e,'11/30/2007')
        e = @user.text_field(:id, 'payment_description')
        assert e.exists?, 'field payment_description should exist'
        @user.populate(e,'Paid total: $5.00')
        @user.wait()
        @user.submits()
      end
    end	

    assert @user.contains_text('Payment was successfully recorded')
    p = Payment.find(:first, :order => 'id desc')
    i = Invoice.find(invoices(:draft_invoice).id)
    pa = p.pay_applications.find_by_invoice_id(invoices(:draft_invoice).id)
    
    assert_equal 'credit card', p.pay_type
    assert_equal i.total_amount, p.amount
    assert_equal Date.new(2007, 11, 30), p.date
    assert_equal 'Paid total: $5.00', p.description
    assert_equal 'recorded', p.status

    #verify pay application has correct values
  	assert_equal i.total_amount, pa.amount
	 
    assert_equal 'paid', i.status	
  end

  # The status must change to paid once the Invoice is 
  # fully paid
  def test_record_payment_and_verify_status_sent
  	@user = watir_session.with(:basic_user)
    @user.logs_in

  
	@user.displays_invoice_list()
	i = Invoice.find(invoices(:sent_invoice).id)
	assert_equal 'sent', i.status
	
  	@user.edits_invoice(invoices(:sent_invoice).id)
    #@user.sets_invoice_info(:unique => "Inv-0001")
    #@user.sets_invoice_contact(:first_name => "My Contact First Name",
	#	:last_name => "My Contact Last Name")
    @user.populate(@user.text_field(:id, "invoice_discount_value"),"10.00")
    @user.select_list(:id, "invoice_discount_type").option(:text, "percent").select

    assert_equal 2, @user.adds_line_item(:unit => "Item A",
					:description => "Description for Item A",
					:quantity => "10.0",
					:price => "5.50")


	# Submit and verify
	assert_difference 'LineItem.count', 1 do
    	@user.submits        
    end

	@user.link(:name, 'record_payment').click
	@user.wait()
	
    assert_difference 'Payment.count' do
      assert_difference 'PayApplication.count' do
        #Enter payment information.
        e = @user.select_list(:id, 'payment_pay_type')
        assert e.exists?, 'Should have payment field payment_pay_type'
        e.select('cash')
        e = @user.text_field(:id, 'payment_amount')
        assert e.exists?, 'field payment_amount should exist'
        @user.populate(e,(58.50).to_s)
        e = @user.text_field(:id, 'payment_date')
        assert e.exists?, 'field payment_date should exist'
        @user.populate(e,'11/30/2007')
        e = @user.text_field(:id, 'payment_description')
        assert e.exists?, 'field payment_description should exist'
        @user.populate(e,'Paid total: $58.50')
        @user.wait()
        @user.submits()
      end
    end	

    assert @user.contains_text('Payment was successfully recorded')
    p = Payment.find(:first, :order => 'id desc')
    i = Invoice.find(invoices(:sent_invoice).id)
    pa = p.pay_applications.find_by_invoice_id(invoices(:sent_invoice).id)
    
    assert_equal 'cash', p.pay_type
    assert_equal i.total_amount.to_s, p.amount.to_s
    assert_equal Date.new(2007, 11, 30), p.date
    assert_equal 'Paid total: $58.50', p.description
    assert_equal 'recorded', p.status

    #verify pay application has correct values
  	assert_equal i.total_amount, pa.amount
	 
    assert_equal 'paid', i.status	
  end
	
  # The status must change to paid once the Invoice is 
  # fully paid
  def test_record_payment_and_verify_status_resent
  	@user = watir_session.with(:basic_user)
    @user.logs_in

  	@user.displays_invoice_list()
  	i = Invoice.find(invoices(:resent_invoice).id)
  	assert_equal 'resent', i.status
	
  	@user.edits_invoice(invoices(:resent_invoice).id)
    #@user.sets_invoice_info(:unique => "Inv-0001")
    #@user.sets_invoice_contact(:first_name => "My Contact First Name",
	#	:last_name => "My Contact Last Name")
    @user.populate(@user.text_field(:id, "invoice_discount_value"),"10.00")
    @user.select_list(:id, "invoice_discount_type").option(:text, "percent").select

    assert_equal 2, @user.adds_line_item(:unit => "Item A",
					:description => "Description for Item A",
					:quantity => "10.0",
					:price => "5.50")

	# Submit and verify
	assert_difference 'LineItem.count', 1 do
    	@user.submits        
    end

	@user.link(:name, 'record_payment').click
	@user.wait()
	
    assert_difference 'Payment.count' do
      assert_difference 'PayApplication.count' do
        #Enter payment information.
        e = @user.select_list(:id, 'payment_pay_type')
        assert e.exists?, 'Should have payment field payment_pay_type'
        e.select('cheque')
        e = @user.text_field(:id, 'payment_amount')
        assert e.exists?, 'field payment_amount should exist'
        @user.populate(e,(58.50).to_s)
        e = @user.text_field(:id, 'payment_date')
        assert e.exists?, 'field payment_date should exist'
        @user.populate(e,'11/30/2007')
        e = @user.text_field(:id, 'payment_description')
        assert e.exists?, 'field payment_description should exist'
        @user.populate(e,'Paid total: $58.50')
        @user.wait()
        @user.submits()
      end
    end	

  

    assert @user.contains_text('Payment was successfully recorded')
    p = Payment.find(:first, :order => 'id desc')
    i = Invoice.find(invoices(:resent_invoice).id)
    pa = p.pay_applications.find_by_invoice_id(invoices(:resent_invoice).id)
    
    assert_equal 'cheque', p.pay_type
    assert_equal i.total_amount.to_s, p.amount.to_s
    assert_equal Date.new(2007, 11, 30), p.date

    assert_equal 'Paid total: $58.50', p.description
    assert_equal 'recorded', p.status

    #verify pay application has correct values
  	assert_equal i.total_amount, pa.amount
	 
    assert_equal 'paid', i.status	
  end

  def test_correct_ajax_messages

    @user = watir_session.with(:basic_user)
    @user.logs_in
    @user.creates_new_invoice
    @user.button(:name, "commit").click
    @user.span(:id, "mark_sent").links[1].click
    @user.b.wait
    assert @user.b.html.include?("cannot")
    @user.span(:id, "record_payment").links[1].click
    assert @user.b.html.include?("send it or mark")
    
    @user.creates_new_invoice
    @user.adds_line_item(:unit => 'line two', :quantity => '1', :price => '4.56')
    @user.enter_new_customer( :name => "bob") 
    @user.button(:name, "commit").click
    @user.span(:id, "record_payment").links[1].click
    @user.b.select_list(:id, "payment_pay_type").select("cash")
    @user.populate(@user.b.text_field(:id, "payment_amount"),("2.00"))
    @user.button(:name, "commit").click
    assert @user.b.html.include?("Outstanding Invoice")
  end
  

  private
  def fill_invoice_for user
  
    # Invoice Info
    user.sets_invoice_info(
      :unique => "Inv-0001",
      :date => "2007-12-15",
      :reference => "Ref-0001",
      :description => "Original description for this Invoice"
    )
    
    # Contact Info
    #user.sets_invoice_contact(
    #    :first_name => "My Contact First Name",
    #    :last_name => "My Contact Last Name",
    #    :email => "abc@address.com"
    #)    
  end
  
    def complete_profile_for(user)
      user.profile.company_name = "Company Name"
      user.profile.company_address1 = "Address 1"
      user.profile.company_city = "Vancouver"
      user.profile.company_country = "Canada"
      user.profile.company_state = "British Columbia"
      user.profile.company_postalcode = "V1V 1V1"
      user.profile.company_phone = "123 456 7890"
      return user
    end
  
end
