
  

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

if !$paypal_hidden
# Test cases for User Story 68
class PaypalExpressRoundTrip < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers, :payments, :pay_applications
  
  def setup
    ActiveMerchant::Billing::Base.gateway_mode = :test
    @payer = watir_session
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    unless @paypal_login
      @payer.login_to_paypal_sandbox
      @paypal_login = true
    end
  end

  def teardown
    $log_on = false
    $log_concurrency = true
    @payer.teardown
  end

  def test_should_pay_invoice_from_link
    # using an invoice with an amount owing, generate an access 
    @invoice = unpaid_invoice
    
    # check amount owing
    assert (@invoice.amount_owing > 0)

    @payer.current_access_key = @invoice.create_access_key
    # follow the access link

    assert_difference 'Payment.count' do
      @payer.clicks_on_direct_payment
    end

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?
    
    @payer.with_paypal_sandbox_retry do
      @payer.logs_in_to_paypal_buyer_account
    end
    assert @payer.contains_text(@invoice.unique)
    
    @payer.with_paypal_sandbox_retry do
      @payer.confirms_payment_in_paypal
    end
    
    p.reload
    puts "want confirming: p.status: #{p.status.inspect}" if $log_on
    assert p.confirming?
    
#    sleep 10
#    assert @payer.contains_text(@invoice.unique)
#    assert @payer.contains_text(@invoice.total_amount.to_s)
    
    @payer.submits
    
    p.reload
    puts "want cleared: p.status: #{p.status.inspect}" if $log_on
    assert p.cleared?
    @invoice.reload
    assert_equal 0, @invoice.amount_owing
  end

  def test_should_cancel_paypal_on_paypal
    # using an invoice with an amount owing, generate an access 
    @invoice = unpaid_invoice
    
    # check amount owing
    assert (@invoice.amount_owing > 0)
    orig_amount_owing = @invoice.amount_owing

    @payer.current_access_key = @invoice.create_access_key
    # follow the access link

    assert_difference 'Payment.count' do
      @payer.clicks_on_direct_payment
    end

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?

    @payer.with_paypal_sandbox_retry do
      @payer.logs_in_to_paypal_buyer_account
    end
    assert @payer.contains_text(@invoice.unique)

    @payer.with_paypal_sandbox_retry do
      @payer.cancels_payment_in_paypal
    end
    
    p.reload
    @invoice.reload
    
    puts "wants cancelled_no_redo p.status: #{p.status.inspect}" if $log_on
    assert p.cancelled_no_redo?

    assert_equal orig_amount_owing, @invoice.amount_owing
  end
  
  def test_should_cancel_paypal_on_tornado
    # using an invoice with an amount owing, generate an access 
    @invoice = unpaid_invoice
  
    # check amount owing
    assert (@invoice.amount_owing > 0)
    orig_amount_owing = @invoice.amount_owing
  
    @payer.current_access_key = @invoice.create_access_key
    # follow the access link
  
    puts "#{Time.now} do click on direct payment"
    assert_difference 'Payment.count' do
      @payer.clicks_on_direct_payment
    end
  
    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?
  
    puts "#{Time.now} do paypal login"
    @payer.with_paypal_sandbox_retry do
      @payer.logs_in_to_paypal_buyer_account
    end
    assert @payer.contains_text(@invoice.unique)

    puts "#{Time.now} do confirm"
    @payer.with_paypal_sandbox_retry do
      @payer.confirms_payment_in_paypal
    end
    
    puts "assert we are on confirm page"
    assert @payer.contains_text('Please confirm payment of')
    
    sleep 1
    puts "reload payment"
    sleep 1
    
    p.reload
    puts "#{Time.now} want confirming: p.status: #{p.status.inspect}" if $log_on
    assert p.confirming?
    
    @payer.cancels
    
    p.reload
    @invoice.reload
    puts "want cancelled: p.status: #{p.status.inspect}" if $log_on
    assert p.cancelled?
  
    assert_equal orig_amount_owing, @invoice.amount_owing
  end
  
  # def test_should_cancel_paypal_before_login
  # end
  # 
  # def test_backbutton_after_redirect_should_refire_redirect
  # end
  # 
  # def test_backbutton_twice_after_paypal_confirm_should_go_to_confirm
  # end
  # 
  # def test_all_intermediate_urls_after_cancel_should
  # end
  # 
  # def test_should_create_only_one_payment_when_hitting_paylink_twice
  # end
  # 
  # def test_should_create_new_payment_when_hitting_paylink_after_cancelling
  # end
  # 
  # def test_should_handle_back_button_after_cancelling_on_paypal
  #   # payment will be in cancelled state. A new payment should be created.
  # end
  # 
  
  private
  
  def unpaid_invoice
    invoice = invoices(:unpaid_invoice_1)
    add_paypal_credentials(invoice.created_by)
    invoice
  end
  
end

end