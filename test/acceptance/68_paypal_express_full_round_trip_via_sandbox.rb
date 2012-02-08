$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

if !$paypal_hidden
# Test cases for User Story 68
class PaypalExpressFullRoundTrip < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :invoices

  def setup
    @browser = watir_session.with(:basic_user)
    @login_id = paypal_test_api_merchant_account
  end
  
  def teardown 
    @browser.teardown
    $log_on = false
    @invoice.destroy
  end

  # Complete Happy Path 
  def test_happy_path_should_create_and_pay_invoice

    #this is the complete test, so we are going to create a user
    @browser = watir_session
  # STEP 1. A new user signs up, creates an Invoice and sends it using
  # paypal
    signsup_creates_and_sends_invoice  

    # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true

        login_to_paypal_for @payer

    pay_invoice_from_link

    @payer.close

 
      # STEP 3. The user logs in an checks that the Invoice has been 
      # paid
      puts "log in" if $log_on 
    @browser.goto(@browser.login_url)
        @browser.text_field(:id,"login").set(@login_id)
        @browser.text_field(:id,"password").set("simply#1")
        @browser.button(:name, "commit").click
      
        @browser.wait()
        #look for the flash message
      assert_not_nil @browser.contains_text("Logged in successfully")  

    @browser.displays_invoice_list
  
    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end
  
  def test_multiple_clicks_direct_pay_should_refire_redirect
    setup_invoice_to_be_paid

    # STEP 2. The customer logs to Paypal and pays the Invoice

      # First Click to Direct Pay
    @payer = watir_session 

    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
      login_to_paypal_for @payer

    direct_payment_for @payer

      p = Payment.find(:first, :order => 'id DESC')
      assert p.waiting_for_gateway?, "expecting status! waiting_for_gateway but got #{p.status}"

    puts "do payer 2" if $log_on 
      # Second Click to Direct Pay  
    @payer2 = watir_session 
    @payer2.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
      #login_to_paypal_for @payer2

    @payer2.current_access_key = @payer.current_access_key
    @payer2.clicks_on_direct_payment

    p.reload
    assert p.waiting_for_gateway?, "expecting status! waiting_for_gateway but got #{p.status}"

    logs_in_to_paypal(@payer2)

    p.reload
    assert p.confirming?, "expecting status! confirming but got #{p.status}"

    Watir::Waiter.new(25).wait_until do
      @payer.contains_text("Please confirm payment of")
    end

    @payer2.submits

    
    p.reload
    puts "#{Time.now} want cleared: p.status: #{p.status.inspect}" if $log_on

    sleep 50 if ($log_on and p.status != 'cleared')
    
    assert p.cleared?, "expecting status cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing 
  
    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in

    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)


  end

  def test_multiple_clicks_backbutton_should_refire_redirect

    setup_invoice_to_be_paid
    # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 

    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status! waiting_for_gateway but got #{p.status}"

    @payer.logs_in_to_paypal_buyer_account
    @payer.back

    @payer.wait

    puts "looking for login" if $log_on 
    assert @payer.button(:id, "login.x").exist?

    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in

    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("620.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("waiting_for_gateway", @browser.span(:id, "payment_status").text)

  end
  
  def test_multiple_clicks_should_cancel_paypal_before_login
    setup_invoice_to_be_paid

    # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    @payer.cancels_payment_in_paypal

    #look for the flash message
    p.reload
    puts "looking for Payment Cancelled. status: #{p.status}" if $log_on 

    assert_not_nil @payer.contains_text("Payment Cancelled")

    p.reload
    assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in

    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("620.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cancelled_no_redo", @browser.span(:id, "payment_status").text)

  end
  
  def test_multiple_clicks_should_cancel_paypal_after_login
    setup_invoice_to_be_paid


    # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    @payer.logs_in_to_paypal_buyer_account
    assert @payer.contains_text(@invoice.unique)

    @payer.cancels_payment_in_paypal

    #look for the flash message to see if the profile is updated
    assert_not_nil @payer.contains_text("Payment Cancelled")

    assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in

    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("620.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cancelled_no_redo", @browser.span(:id, "payment_status").text)

  end
  
  def xxxx_test_paypal_cancel_before_login_followed_by_click_direct_pay
    setup_invoice_to_be_paid


    # STEP 2. The customer clicks direct pay and cancels to re-direct to Paypal and pay the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
      login_to_paypal_for @payer

    direct_payment_for @payer

      p = Payment.find(:first, :order => 'id DESC')
      assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    @payer.cancels_payment_in_paypal

      #look for the flash message
      assert_not_nil @payer.contains_text("Payment Cancelled")

    # re-directs to paypal
    direct_payment_for @payer

    # logs-in and confirms
    logs_in_to_paypal

      p.reload
      assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

      @payer.submits

      #look for the flash message
      puts "looking for Payment is successfully recorded." if $log_on 
      sleep 50 if $log_on
      assert_not_nil @payer.contains_text("Payment is successfully recorded.")
    
      p = Payment.find(:first, :order => 'id DESC')
      assert p.cleared?, "expecting status cleared but got #{p.status}"
      @invoice.reload
      assert_equal 0, @invoice.amount_owing 

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end

  def test_paypal_cancel_before_login_followed_by_backbutton
    setup_invoice_to_be_paid


    # STEP 2. The customer clicks direct pay and cancels to re-direct to Paypal and pay the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    @payer.cancels_payment_in_paypal

    #look for the flash message
    assert_not_nil @payer.contains_text("Payment Cancelled")

    # clicks back-button
    @payer.back

    # logs-in and confirms
    logs_in_to_paypal

    p.reload
    assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

    @payer.submits

    #look for the flash message
    puts "looking for Payment is successfully recorded." if $log_on 
    sleep 50 if $log_on
    assert_not_nil @payer.contains_text("Payment is successfully recorded.")

    p = Payment.find(:first, :order => 'id DESC')
    assert p.cleared?, "expecting status cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing 

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in


    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end

  def test_paypal_cancel_after_login_followed_by_click_direct_pay
    setup_invoice_to_be_paid


    # STEP 2. The customer clicks direct pay and cancels to re-direct to Paypal and pay the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
      login_to_paypal_for @payer

    direct_payment_for @payer

      p = Payment.find(:first, :order => 'id DESC')
      assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

      @payer.logs_in_to_paypal_buyer_account
      assert @payer.contains_text(@invoice.unique)

      @payer.cancels_payment_in_paypal

      #look for the flash message
      assert_not_nil @payer.contains_text("Payment Cancelled")

    assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

    # re-directs to paypal
    direct_payment_for @payer

    # logs-in and confirms
    logs_in_to_paypal

      p.reload
      assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

      @payer.submits

      
      assert_not_nil @payer.contains_text("Payment is successfully recorded.")
    
      p = Payment.find(:first, :order => 'id DESC')
      assert p.cleared?, "expecting status cleared but got #{p.status}"
      @invoice.reload
      assert_equal 0, @invoice.amount_owing 

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in


    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end

  def test_paypal_cancel_after_login_followed_by_backbutton
    setup_invoice_to_be_paid


    # STEP 2. The customer clicks direct pay and cancels, then clicks back. Paypal will report not found.

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
      login_to_paypal_for @payer

    direct_payment_for @payer

      p = Payment.find(:first, :order => 'id DESC')
      assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

      @payer.logs_in_to_paypal_buyer_account
      assert @payer.contains_text(@invoice.unique)

      @payer.cancels_payment_in_paypal

      #look for the flash message
      assert_not_nil @payer.contains_text("Payment Cancelled")

    assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

    # clicks back-button
    @payer.back

    # logs-in and confirms
    assert @payer.image(:src, /retry\.gif/).exists?

      p.reload
      assert p.cancelled_no_redo?, "expecting status cancelled_no_redo but got #{p.status}"

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in


    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("620.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cancelled_no_redo", @browser.span(:id, "payment_status").text)

  end

  def xxx_test_tornado_cancel_followed_by_click_direct_pay
    setup_invoice_to_be_paid


  # STEP 2. The customer logs to Paypal and pays the Invoice

@payer = watir_session 
@payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

logs_in_to_paypal

    p.reload
    assert p.confirming?, "expecting status confirming but got #{p.status}"

    @payer.cancels_payment

#look for the flash message to see if the profile is updated
    assert_not_nil @payer.contains_text("Payment Cancelled")

assert !p.waiting_for_gateway?, "expecting status !waiting_for_gateway but got #{p.status}"

# re-directs to paypal
direct_payment_for @payer

# logs-in and confirms
logs_in_to_paypal

    p.reload
assert p.cancelled?, "expecting status cancelled but got #{p.status}"
  
    @payer.submits

    #look for the flash message
    assert_not_nil @payer.contains_text("Payment is successfully recorded.")
    
    p = Payment.find(:first, :order => 'id DESC')
    assert p.cleared?, "expecting status cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing 

@payer.close
 
  # STEP 3. The user logs in an checks that the Invoice has been 
  # paid
  @browser.logs_in


@browser.displays_invoice_list
  
id = (Payment.find(:first, :order => 'id DESC')).id

@browser.shows_payment(id)

# Verify Invoice: Number, Total and Amount Owing
assert_equal("Inv-0001", @browser.span(:name, "unique").text)
assert_equal("620.00", @browser.span(:id, "invoice_total").text)
assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

# Verify Payment: Type, Amount, Status
assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
assert_equal("620.00", @browser.span(:id, "payment_amount").text)
assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end

  def xxx_test_tornado_cancel_followed_by_backbutton_once
    setup_invoice_to_be_paid


  # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    logs_in_to_paypal

    p.reload
    assert p.confirming?, "expecting status confirming but got #{p.status}"

    @payer.cancels_payment
    #look for the flash message to see if the profile is updated
    assert_not_nil @payer.contains_text("Payment Cancelled")

    p.reload
    puts "expecting cancelled 1 -- p.status: #{p.status.inspect}" if $log_on 
    assert p.cancelled?, "expecting status cancelled but got #{p.status}"

    # clicks back button
    puts "back button" if $log_on 
    @payer.back
    Watir::Waiter.new(25).wait_until do
      @payer.contains_text("Please confirm payment of")
    end

    p.reload
    puts "expecting cancelled -- p.status: #{p.status.inspect}" if $log_on 
    assert p.cancelled?, "expecting status cancelled but got #{p.status}"

    @payer.submits

    #look for the flash message

    puts "looking for Payment is successfully recorded." if $log_on 
    Watir::Waiter.new(20).wait_until do
      @browser.contains_text("Payment is successfully recorded.")
    end
    assert_not_nil @payer.contains_text("Payment is successfully recorded.")

    p = Payment.find(:first, :order => 'id DESC')
    assert p.cleared?, "expecting status cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing 

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in


    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end

  def xxx_test_tornado_cancel_followed_by_backbutton_once_plus_reload
    setup_invoice_to_be_paid


    # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    logs_in_to_paypal

    p.reload
    assert p.confirming?, "expecting status confirming but got #{p.status}"

    @payer.cancels_payment

    #look for the flash message to see if the profile is updated
    assert_not_nil @payer.contains_text("Payment Cancelled")

    p.reload
    assert p.cancelled?, "expecting status cancelled but got #{p.status}"

    # clicks back button
    puts "back button" if $log_on 
    @payer.back
    Watir::Waiter.new(25).wait_until do
      @payer.contains_text("Please confirm payment of")
    end

    p.reload
    puts "expecting cancelled -- p.status: #{p.status.inspect}" if $log_on 
    assert p.cancelled?, "expecting status cancelled but got #{p.status}"


    #clicks reload (refresh)
    @payer.refresh

    p.reload
    puts "expecting confirming -- p.status: #{p.status.inspect}" if $log_on 
    assert p.confirming?, "expecting status confirming but got #{p.status}"

    @payer.submits

    #look for the flash message
    assert_not_nil @payer.contains_text("Payment is successfully recorded.")

    p = Payment.find(:first, :order => 'id DESC')
    assert p.cleared?, "expecting status cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing 

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in


    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end

  def xxx_test_tornado_cancel_followed_by_backbutton_twice
    setup_invoice_to_be_paid


    # STEP 2. The customer logs to Paypal and pays the Invoice

    @payer = watir_session 
    @payer.active_merchant_live = ENV['ACTIVE_MERCHANT_LIVE'] || true
    login_to_paypal_for @payer

    direct_payment_for @payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status waiting_for_gateway but got #{p.status}"

    logs_in_to_paypal

    p.reload
    assert p.confirming?, "expecting status confirming but got #{p.status}"

    @payer.cancels_payment

    #look for the flash message to see if the profile is updated
    assert_not_nil @payer.contains_text("Payment Cancelled")

    assert !p.waiting_for_gateway?, "expecting status! waiting_for_gateway but got #{p.status}"

    # clicks back button
    puts "back button" if $log_on 
    @payer.back
    Watir::Waiter.new(25).wait_until do
      @payer.contains_text("Please confirm payment of")
    end

    puts "back button" if $log_on 
    @payer.back
    Watir::Waiter.new(25).wait_until do
      @payer.contains_text("Please confirm payment of")
    end


    p.reload
    assert p.cancelled?, "expecting status! cancelled but got #{p.status}"

    @payer.submits

    #look for the flash message
    assert_not_nil @payer.contains_text("Payment is successfully recorded.")

    p = Payment.find(:first, :order => 'id DESC')
    assert p.cleared?, "expecting status! cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing 

    @payer.close

    # STEP 3. The user logs in an checks that the Invoice has been 
    # paid
    @browser.logs_in


    @browser.displays_invoice_list

    id = (Payment.find(:first, :order => 'id DESC')).id

    @browser.shows_payment(id)

    # Verify Invoice: Number, Total and Amount Owing
    assert_equal("Inv-0001", @browser.span(:name, "unique").text)
    assert_equal("620.00", @browser.span(:id, "invoice_total").text)
    assert_equal("0.00", @browser.span(:id, "invoice_amount_owing").text)

    # Verify Payment: Type, Amount, Status
    assert_equal("paypal_express", @browser.span(:id, "payment_pay_type").text)
    assert_equal("620.00", @browser.span(:id, "payment_amount").text)
    assert_equal("cleared", @browser.span(:id, "payment_status").text)

  end
    
  private
  def signsup_creates_and_sends_invoice
    puts "signsup_creates_and_sends_invoice" if $log_on 
  	# Create a new User from scratch
    sign_up_user

    # Update Profile with Paypal information
    update_profile

    # Create Invoice
    @browser.creates_new_invoice
    fill_invoice_for @browser
    fill_invoice_details_for @browser

    # Sent Invoice with PayPal
    click_send
    send_email_with_paypal_link_and_sleep(1)



    #Verify draft status string
      assert @browser.contains_text("Email was successfully delivered")

    # Merchant signs off
    @browser.goto(@browser.logoff_url)
    @browser.wait

    # Verify logoff
      assert @browser.contains_text("You have been logged out.")  

  end
  
  def setup_invoice_to_be_paid(username=:basic_user)
    @browser.username = username
    add_paypal_credentials(users(username))

    @invoice = add_valid_invoice(users(username), {:unique_name => "Inv-0001", :line_items => [{:price => 620}]})
    assert_equal 620, @invoice.amount_owing
  end
  
  def sign_up_user
    puts "sign_up_user" if $log_on 
    @browser.goto_create_account_url
    
    
    sleep 5
    @browser.text_field(:id,"user_login").set(@login_id)
    @browser.text_field(:id,"user_password").set("simply#1" )
    @browser.text_field(:id,"user_password_confirmation").set("simply#1")
    @browser.checkbox(:id, "user_terms_of_service").set
    assert_difference 'User.count' do
        @browser.button(:value, "Sign up").click
    end
    
    @browser.wait
    #look for the flash message to see if the account is created
    assert_not_nil @browser.contains_text("Thanks for signing up")
  
  end
  
  def update_profile
    puts "update_profile" if $log_on 
    @browser.goto_profile_url
    @browser.text_field(:id, "profile_company_name").set("Merchant")
    @browser.select_list(:id, "profile_paypal_account_type").select("Paypal Business")        
    @browser.text_field(:id, "profile_paypal_user_id").set(paypal_test_api_username)    
    @browser.text_field(:id, "profile_paypal_password").set(paypal_test_api_password)    
    @browser.text_field(:id, "profile_paypal_API_key").set(paypal_test_api_key)    
    @browser.text_field(:id, "profile_paypal_email_address").set(@login_id)    
    
    @browser.submits

    @browser.wait
    #look for the flash message to see if the profile is updated
    assert_not_nil @browser.contains_text("Setting was successfully updated")
	
  end
  
  def fill_invoice_for user
    puts "fill_invoice_for" if $log_on 
  	# Customer Info
    user.enter_new_customer(user, 
        :name => "Buyer"
    )
  
    # Invoice Info
    user.sets_invoice_info(
      :unique => "Inv-0001",
      :date => "2007-12-15",
      :reference => "Ref-0001",
      :description => "Invoice with 5 Items - Pay with PayPal, please"
    )
    
    # Contact Info
    #user.sets_invoice_contact(
    #    :first_name => "Buyers",
    #    :last_name => "Contact",
    #    :email => "autotest@10.152.17.65"
    #)    
  end
  
  def fill_invoice_details_for user
    puts "fill_invoice_details_for" if $log_on 
    number_of_line_items = 5
    subtotal = 0
    discount = 50.00
    discount_percent = 10.00
    quantity = 20
    price = 4.00

    # Add line items
    (1..number_of_line_items).each do | i |
      if i == 1 
         user.edits_line_item(i, 
          :unit => "Item A" + i.to_s,
          :description => "Description for Item A" + i.to_s,
          :quantity => quantity.to_s,
          :price => price.to_s)
      else
        assert_equal i, user.adds_line_item(
          :unit => "Item A" + i.to_s,
          :description => "Description for Item A" + i.to_s,
          :quantity => quantity.to_s,
          :price => price.to_s)
      end
      subtotal += quantity * price          
      quantity += 1
      price += 1
    end

    # Discount and Type
    user.text_field(:id, "invoice_discount_value").set(discount.to_s)
    user.select_list(:id, "invoice_discount_type").option(:text, "amount").select
	  
    # Submit and verify
    assert_difference 'LineItem.count', number_of_line_items do
      user.submits        
    end	  

    @browser.wait
    #look for the flash message to see if the profile is updated
    assert_not_nil @browser.contains_text("invoice was successfully created")
	
  end
  
  def click_send
    puts "click_send" if $log_on 
    #Verify draft status string
    assert @browser.contains_text("draft")
    
    #send the invoice
    @browser.link(:text, "Send").click
    @browser.wait
  end
  
  def send_email_with_paypal_link_and_sleep(seconds)
    puts "send_email_with_paypal_link_and_sleep" if $log_on 
    # set the contact email, maybe this will be done automatically later
    @browser.text_field(:id, "delivery_recipients").set("autotest@10.152.17.65")
    @browser.text_field(:id, "delivery_body").set("Inv-001 - Sent by PayPal")
    @browser.checkbox(:id, "delivery[mail_options][include_direct_payment]").click

    # get the deliverableId from a hidden field and use later to read the deliveries table
    @deliverableId = @browser.hidden(:id, "delivery_deliverable_id").value
    
    @browser.button(:value, "Send").click
    @browser.wait 
    # sleep until the email is delivered
    # sleep seconds
	
    #look for the flash message to see if the profile is updated
    Watir::Waiter.new(20).wait_until do
      @browser.contains_text("Email was successfully delivered")
    end
    assert_not_nil @browser.contains_text("Email was successfully delivered")
	
  end
  
  def login_to_paypal_for payer
    puts "login_to_paypal_for" if $log_on 
    unless @paypal_login
      payer.login_to_paypal_sandbox
      @paypal_login = true
    end  
  end
  
  def pay_invoice_from_link(payer=@payer)
  	puts "pay_invoice_from_link" if $log_on 
  	direct_payment_for payer

    p = Payment.find(:first, :order => 'id DESC')
    assert p.waiting_for_gateway?, "expecting status! waiting_for_gateway but got #{p.status}"

	  logs_in_to_paypal payer
	  
    p.reload
    assert p.confirming?, "expecting status! confirming but got #{p.status}"

    @payer.submits
    
    p.reload
    assert p.cleared?, "expecting status! cleared but got #{p.status}"
    @invoice.reload
    assert_equal 0, @invoice.amount_owing	
  end
  
  def direct_payment_for payer
    puts "direct_payment_for" if $log_on 
    # using an invoice with an amount owing, generate an access 
    @invoice ||= Invoice.find(:first, :order => 'id DESC')
	
    # check amount owing
    puts "amount owing of invoice: #{@invoice.amount_owing.inspect}" if $log_on
    assert (@invoice.amount_owing == 620.00)

    payer.current_access_key = @invoice.create_access_key
    # follow the access link

    assert_difference 'Payment.count' do
      payer.clicks_on_direct_payment
    end

  end
	  
  def logs_in_to_paypal(payer=@payer)
    puts "logs_in_to_paypal" if $log_on 
    payer.logs_in_to_paypal_buyer_account
    assert payer.contains_text(@invoice.unique)
    payer.confirms_payment_in_paypal
  end
  
end

end
