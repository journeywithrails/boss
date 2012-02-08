require File.dirname(__FILE__) + '/../test_helper'

class TestGateway
  attr_accessor :payment, :gateway, :controller, :invoice, :access_key; 
  def supported_cardtypes; []; end
  def form_partial; 'online_payments/beanstream_form'; end
  def name; 'test'; end
end

class OnlinePaymentsControllerTest < ActionController::TestCase

  # show ------------------

  #user story should pay invoice through paypal.
  def test_should_get_direct_payment
    setup_expectations_for_direct
    @payment.expects(:pay!).with(@controller, 'test', '12345').returns("http://www.somewhere.com")
    @payment.stubs(:active?).returns(true)
    @payment.expects(:ip=).with('0.0.0.0')
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :redirect
    assert_same @payment, assigns(:payment)
    assert_redirected_to "http://www.somewhere.com"
  end
  
  def test_should_display_not_found_for_direct_when_invoice_not_accessible
    Payment.expects(:direct_payment_for_access_key).returns(:some_payment)
    AccessKey.expects(:find_by_key).with('12345').returns(nil)
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :missing
    assert_template 'access/not_found'
  end
  
  def test_should_display_unable_when_gateway_returns_no_url
    setup_expectations_for_direct
    @payment.expects(:pay!).with(@controller, 'test', '12345').returns(nil)
    @payment.stubs(:active?).returns(true)
    @payment.expects(:ip=).with('0.0.0.0')
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_template 'unable'
  end

  # move to test_payments (billing_process_response)
 #def test_should_display_unable_when_other_payment_in_progress
 #  setup_expectations_for_direct
 #  Payment.expects(:create_locked_for_invoice).raises(Sage::BusinessLogic::Exception::PaymentInProgressException)
 #  get :direct, :invoice_id => '12345', :id => 'test'
 #  assert_response :success
 #  assert_template 'online_payments/unable'
 #end
  
  def test_should_restart_when_payment_in_progress_cancelled_or_error
    setup_expectations_for_direct
    @payment.expects(:pay!).with(@controller, 'test', '12345').returns("http://www.somewhere.com")
    @payment.stubs(:active?).returns(true)
    @payment.expects(:ip=).with('0.0.0.0')
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :redirect
    assert_same @payment, assigns(:payment)
    assert_redirected_to "http://www.somewhere.com"
  end


  def test_direct_should_handle_billing_error_on_pay
    setup_expectations_for_direct
    @payment.expects(:pay!).with(@controller, 'test', '12345').raises(Sage::BusinessLogic::Exception::BillingError, 'omg')
    @payment.stubs(:active?).returns(true)
    @payment.expects(:ip=).with('0.0.0.0')
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_template 'online_payments/unable'
  end

  def test_should_display_paid_when_nothing_owing
    setup_expectations_for_direct(true, false)
    @payment.stubs(:active?).returns(true)
    @payment.expects(:ip=).with('0.0.0.0')
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_template "online_payments/already_paid"
  end

  def test_should_display_unable_when_same_payment_in_progress
    setup_expectations_for_direct(false)
    get :show, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_template 'online_payments/unable'
  end










  # create ------------------

  def test_should_successfully_submit_payment
    setup_submit_payment
    setup_not_fully_paid
    response = mock('response')
    @payment.expects(:payment_type).returns('amex')
    @invoice.expects(:selected_payment_type?).with('amex').returns(true)
    @payment.expects(:process_payment_params).returns([true, [@card, @billing_address]])
    @payment.expects(:submit!).with(@controller, '12345', [@card, @billing_address]).returns(response)
    @payment.expects(:ip=).with('0.0.0.0')
    response.expects(:success?).returns(true)
    @invoice.expects(:acknowledge_payment).with(true)
    post :create, :invoice_id => '12345', :card => "card_info", :billing_address => "address_info"
    assert_template('online_payments/complete')
  end

  def test_should_handle_payment_failure
    setup_submit_payment
    setup_not_fully_paid
    response = mock('response')
    @payment.expects(:payment_type).times(3).returns('amex')
    @invoice.expects(:selected_payment_type?).times(2).with('amex').returns(true)
    @payment.expects(:process_payment_params).returns([true, [@card, @billing_address]])
    @payment.expects(:submit!).with(@controller, '12345', [@card, @billing_address]).returns(response)
    @payment.expects(:ip=).with('0.0.0.0')
    response.expects(:success?).returns(false)
    response.expects(:message).returns('You have no money')
    @invoice.expects(:acknowledge_payment).never
    post :create, :invoice_id => '12345', :card => "card_info", :billing_address => "address_info"
    assert_template('online_payments/new')
  end

  def test_should_not_allow_submit_payment_twice
    setup_submit_payment
    setup_fully_paid
    @payment.expects(:submit!).never
    @payment.expects(:ip=).with('0.0.0.0')
    @invoice.expects(:acknowledge_payment).never
    post :create, :invoice_id => '12345', :card => "card_info", :billing_address => "address_info"
    assert_template('online_payments/already_paid')
  end

  def test_should_handle_redirect_response
    setup_submit_payment
    setup_not_fully_paid
    response = Class.new
    @payment.expects(:payment_type).returns('amex')
    @invoice.expects(:selected_payment_type?).with('amex').returns(true)
    @payment.stubs(:process_payment_params).returns([true, [@card, @billing_address]])
    @payment.expects(:submit!).with(@controller, '12345', [@card, @billing_address]).returns(response)
    @payment.expects(:ip=).with('0.0.0.0')
    response.expects(:success?).returns(true)
    def response.custom_render(controller)
      controller.send :render, :nothing => true
    end
    assert response.respond_to?(:custom_render)
    @invoice.expects(:acknowledge_payment).never
    post :create, :invoice_id => '12345', :card => 'card_info', :billing_address => 'address_info'
  end

  def test_should_handle_invalid_params
    setup_submit_payment
    setup_not_fully_paid
    @payment.expects(:payment_type).times(3).returns('amex')
    @invoice.expects(:selected_payment_type?).times(2).with('amex').returns(true)
    @payment.expects(:process_payment_params).returns([false, [@card, @billing_address]])
    @payment.expects(:submit!).never
    @payment.expects(:ip=).with('0.0.0.0')
    @invoice.expects(:acknowledge_payment).never
    post :create, :invoice_id => '12345', :card => "card_info", :billing_address => "address_info"
    assert_template('online_payments/new')
  end



  # confirm ------------------------------

  def test_should_get_confirm
    setup_mock_invoice_and_gateway true
    payment_details = {:something => 'dontcare'}
    @gateway.expects(:handle_confirmation).returns(payment_details)
    @payment.expects(:billing_process_response).yields.returns(nil)
    @payment.expects(:amount).returns(100)
    @payment.expects(:ip=).with('0.0.0.0')
    @recipient.expects(:user_gateway).with('test').returns(OpenStruct.new(:email => 'a@b.com'))
    Payment.expects(:with_process_lock).with(@payment, 'confirm').yields(@payment)
    get :confirm, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_same @invoice, assigns(:invoice)
    assert assigns(:payment)
    assert_same payment_details, assigns(:payment_details)
    assert_template 'online_payments/confirm'
  end
  
  def test_should_display_unable_when_gateway_returns_no_payment_details
    setup_mock_invoice_and_gateway(true)
    @gateway.expects(:handle_confirmation).returns(nil)
    @payment.expects(:billing_process_response).yields.returns(nil)
    @payment.expects(:ip=).with('0.0.0.0')
    Payment.expects(:with_process_lock).with(@payment, 'confirm').yields(@payment)
    @recipient.expects(:user_gateway).with('test').returns(OpenStruct.new(:email => 'a@b.com'))
    get :confirm, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_template 'online_payments/unable'
  end


  # beanstream_interac_approved ------------

  def test_should_get_interac_approved_successful
    setup_mock_invoice_and_gateway(true)
    response = mock('response')
    @payment.expects(:billing_process_response).yields.returns(nil)
    @gateway.expects(:process_gateway_result).returns(response)
    response.expects(:success?).returns(true)
    @invoice.expects(:acknowledge_payment).with(true)
    @controller.expects(:render_payment_form).never
    @payment.expects(:ip=).with('0.0.0.0')
    get :beanstream_interac_approved, :invoice_id => "12345", :abc => '123', :def => '321'
    assert_template('online_payments/complete')
  end

  def test_should_get_interac_approved_unsuccessful
    setup_mock_invoice_and_gateway(true)
    response = mock('response')
    @payment.expects(:billing_process_response).yields.returns(nil)
    @gateway.expects(:process_gateway_result).returns(response)
    response.expects(:success?).returns(false)
    response.expects(:message).returns("let's hope they give good error messages")
    @invoice.expects(:acknowledge_payment).never
    @payment.expects(:ip=).with('0.0.0.0')
    get :beanstream_interac_approved, :invoice_id => "12345", :abc => '123', :def => '321'
    assert_redirected_to(new_invoice_online_payment_path(:invoice_id => '12345'))
  end

  # beanstream_interac_declined ------------

  def test_should_get_interac_declined
    setup_mock_invoice_and_gateway true
    @payment.expects(:billing_process_response).yields.returns(nil)
    @payment.expects(:fail!)
    @payment.expects(:ip=).with('0.0.0.0')
    get :beanstream_interac_declined, :invoice_id => '12345'
    assert_redirected_to(new_invoice_online_payment_path(:invoice_id => '12345'))
  end

  # complete ----------------
  
  def test_should_get_complete
    setup_mock_invoice_and_gateway(true)
    payment_details = {:something => 'dontcare'}
    @gateway.expects(:complete_purchase).returns(payment_details)
    @payment.expects(:billing_process_response).yields.returns(nil)
    @payment.expects(:ip=).with('0.0.0.0')
    @invoice.expects(:acknowledge_payment)
    get :complete, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_same @payment, assigns(:payment)
    assert_same @invoice, assigns(:invoice)
    assert_template 'online_payments/complete'
    assert_match /#{_("Payment is successfully recorded. Thank You.")}/, @response.body
  end
  
  def test_should_get_complete_when_logged_in
    login_as :basic_user
    setup_mock_invoice_and_gateway(true)
    payment_details = {:something => 'dontcare'}
    @gateway.expects(:complete_purchase).returns(payment_details)
    @payment.expects(:billing_process_response).yields.returns(nil)
    @payment.expects(:ip=).with('0.0.0.0')
    @invoice.expects(:acknowledge_payment)
    get :complete, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_same @payment, assigns(:payment)
    assert_same @invoice, assigns(:invoice)
    assert_template 'online_payments/complete'
    #The following lines for testing issue #1489
    assert_match /#{_("Payment is successfully recorded. Thank You.")}/, @response.body
  end
  
  def test_should_display_unable_when_gateway_returns_false_for_purchase
    setup_mock_invoice_and_gateway(true)
    @gateway.expects(:complete_purchase).returns(false)
    @payment.expects(:billing_process_response).yields.returns(nil)
    @payment.expects(:cancelled?).returns(false)
    @payment.expects(:ip=).with('0.0.0.0')
    get :complete, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_template 'online_payments/unable'
  end


  # cancel -----------------------------------

  def test_should_get_cancel
    setup_mock_invoice_and_gateway(true)
    @payment.expects(:status).returns(:confirming)
    @payment.expects(:cancel!)
    @payment.expects(:cancelled?).returns(true)
    @payment.expects(:ip=).with('0.0.0.0')
    get :cancel, :invoice_id => '12345', :id => 'test'
    assert_response :success
    assert_same @invoice, assigns(:invoice)
    assert_template 'online_payments/cancel'
  end


  # other methods ---------------------------

  def test_beanstream_interac_response_urls
    get :switch_country
    assert_equal({ :approved_url =>
                     "http://#{host_for_test}/invoices/key/online_payments/beanstream_interac_approved",
                   :declined_url =>
                     "http://#{host_for_test}/invoices/key/online_payments/beanstream_interac_declined"
                 },
                 @controller.beanstream_interac_response_urls('key'))
  end

  def test_paypal_response_urls
    get :switch_country # to set up the controller
    assert_equal(["http://#{host_for_test}/invoices/key/online_payments/confirm", "http://#{host_for_test}/invoices/key/online_payments/cancel"],
                 @controller.paypal_response_urls('key'))
  end

  def test_billing_process_response_with_no_param
    payment = mock
    payment.expects(:billing_process_response).with(:some_state).returns(:cancel_page)
    @controller.expects(:cancel_page).with()
    @controller.instance_variable_set('@payment', payment)
    @controller.instance_eval do
      billing_process_response(@payment, :some_state)
    end
  end

  def test_billing_process_response_with_param
    payment = mock
    payment.expects(:billing_process_response).with(:some_state).returns([:cancel_page, 'some message'])
    @controller.expects(:cancel_page).with('some message')
    @controller.instance_variable_set('@payment', payment)
    @controller.instance_eval do
      billing_process_response(@payment, :some_state)
    end
  end

  protected

  def setup_submit_payment
    @invoice = Invoice.new(:currency => 'USD', :total_amount => 123.45)
    setup_find_by_key
    @payment = mock('Payment')
    Payment.expects(:find_active_with_access_key).with('12345').returns(@payment)
    @payment.stubs(:active?).returns(true)
    @payment.stubs(:current_state).returns(:created)

    @card = stub_everything('CreditCard', :valid? => true, :errors => stub_everything(:count => 0), :type => 'master')
    @billing_address = stub_everything('BillingAddress', :valid? => true, :errors => stub_everything(:count => 0), :country_settings => stub_everything(:partial => 'unknown_country'))
    ActiveMerchant::Billing::CreditCard.stubs(:new).returns(@card)
    BillingAddress.stubs(:new).returns(@billing_address)

    @controller.stubs(:billing_process_response).yields
  end

  def setup_not_fully_paid
    @invoice.expects(:fully_paid?).returns(false)
    @gateway = TestGateway.new
    @payment.stubs(:gateway).returns(@gateway)
  end

  def setup_fully_paid
    @invoice.expects(:fully_paid?).returns(true)
  end

  def setup_find_by_key
    @ak = mock('access_key')
    AccessKey.expects(:find_by_key).with('12345').returns(@ak)
    @ak.expects(:nil?).returns(false)
    @ak.expects(:use?).returns(true)
    @ak.expects(:keyable_id).returns(123321)
    Invoice.expects(:find).with(123321).returns(@invoice)
  end
  
  def setup_expectations_for_direct(has_payment = true, not_fully_paid = true)
    if has_payment
      @payment = mock('Payment')
      Payment.expects(:direct_payment_for_access_key).with('12345', 'test').returns(@payment)
      @invoice = mock('invoice')
      setup_find_by_key
      if not_fully_paid
        setup_not_fully_paid
      else
        setup_fully_paid
      end
    else
      Payment.expects(:direct_payment_for_access_key).with('12345', 'test').returns(nil)
    end
  end

  def setup_mock_invoice_and_gateway(has_payment=false)
    @invoice = mock('invoice') # the object we are paying for
    @invoice.stubs(:unique).returns('bobs_nifty_invoice')
    @payment = mock('payment')
    setup_find_by_key
    @recipient = OpenStruct.new(:profile => OpenStruct.new)
    @payment.stubs(:recipient).returns(@recipient)    
    @gateway = TestGateway.new
    @payment.stubs(:gateway).returns(@gateway)
    Payment.stubs(:find_active_with_access_key).returns(@payment)
    Payment.stubs(:get_process_lock).with(@payment).returns(@payment)
    @payment.stubs(:release_process_lock)
  end
  
end
