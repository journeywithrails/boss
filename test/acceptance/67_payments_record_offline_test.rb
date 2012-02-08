$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 67:
# Users can record payments offline.
#
# Description: As a user, I want to record payments which I received from my customers
# so that I know which invoices have already been paid and which ones I still need to collect money.
# Acceptance test cases:
#1. Users can record payment against a specific invoice
#2. Users can specify the type of payment
#3. Users can specify the payment amount
#4. Users can specify the payment date
#5. Users can enter notes, which could be used to store the credit card number, cheque number etc
#6. Once the payment has been recorded, the invoice is now marked as paid

class PaymentsRecordOfflineTest < SageAccepTestCase
  
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers, :payments
  
  def setup
    @user = watir_session.with(:user_for_payments)
    @user.logs_in
  end
  
  def teardown
    $log_on = false
    $log_concurrency = false    
     @user.teardown
  end

  #acceptance cases 1-5: Users can record payment against a specific invoice
  # Users can specify the type, amount, date of payment, and notes
  def test_should_record_payment_against_invoice
    @user.shows_invoice(invoices(:unpaid_invoice_1).id)
    pay = @user.link(:name, 'record_payment')
    assert pay.exists?
    pay.click
    @user.wait()
    
    assert_difference 'Payment.count' do
      assert_difference 'PayApplication.count' do
        #Enter payment information.
        e = @user.select_list(:id, 'payment_pay_type')
        assert e.exists?, 'Should have payment field payment_pay_type'
        e.select('cheque')
        e = @user.text_field(:id, 'payment_amount')
        assert e.exists?, 'field payment_amount should exist'
        @user.populate(e, invoices(:unpaid_invoice_1).total_amount.to_s)
        e = @user.text_field(:id, 'payment_date')
        assert e.exists?, 'field payment_date should exist'
        @user.populate(e, '11/30/2007')
        e = @user.text_field(:id, 'payment_description')
        assert e.exists?, 'field payment_description should exist'
        @user.populate(e, 'Some notes')
        @user.wait()
        @user.submits()
      end
    end

    @user.wait()
    puts "looking for payment was successfully recorded" if $log_on 
    assert @user.contains_text('Payment was successfully recorded')
 
    p = Payment.find(:first, :order => 'id desc')
    i = Invoice.find(invoices(:unpaid_invoice_1).id)
    pa = p.pay_applications.find_by_invoice_id(invoices(:unpaid_invoice_1).id)
    
    assert_equal 'cheque', p.pay_type
    assert_equal i.total_amount, p.amount
    assert_equal Date.new(2007, 11, 30), p.date
    assert_equal 'Some notes', p.description
    assert_equal 'recorded', p.status

    #verify pay application has correct values
    assert_equal i.total_amount, pa.amount

    #acceptance case #6. Once the payment has been recorded, the invoice is now marked as paid
    assert_equal 'paid', i.status
  end

  def test_dsl_payment_with_invoice
    #create payment
    @user.creates_new_payment_for_invoice(invoices(:unpaid_invoice_1).id).sets_payment(
      :pay_type => 'cheque',
      :amount => '50.00',
      :date => 'November 29, 2007',
      :description => 'Deposit of $50.00'
    ).and_submits
    assert @user.contains_text('Payment was successfully recorded')
    p = Payment.find(:first, :order => 'id desc')
  end
  
end