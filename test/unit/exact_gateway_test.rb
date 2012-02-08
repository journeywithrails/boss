require File.dirname(__FILE__) + '/../test_helper'

class ExactGatewayTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

  def setup
    @g = ExactGateway.new
    @g.stubs(:logger).returns(stub_everything)
  end

	def test_display_recipient_name
		#make sure there is a description of the gateway for recipient of the invoice
		assert_not_nil ExactGateway.display_recipient_name
  end

  def test_handle_invoice_cad
    ug = ExactUserGateway.new(:currency => 'CAD')
    assert @g.handle_invoice?(mock(:user_gateway => ug, :currency => 'CAD'))
    assert !@g.handle_invoice?(mock(:user_gateway => ug, :currency => 'USD'))
  end

  def test_handle_invoice
    ug = ExactUserGateway.new(:currency => 'USD')
    assert !@g.handle_invoice?(mock(:user_gateway => ug, :currency => 'CAD'))
    assert @g.handle_invoice?(mock(:user_gateway => ug, :currency => 'USD'))
  end

  def test_amount_as_cents_normal
    payment = mock(:amount_as_cents => 1000, :max_invoice_amount => 2000)
    @g.payment = payment
    assert_equal 1000, @g.amount_as_cents
  end

  def test_amount_as_cents_too_much
    payment = mock(:amount_as_cents => 3000, :max_invoice_amount => 2000)
    @g.payment = payment
    assert_equal 2000, @g.amount_as_cents
  end

  def test_gateway_class
    assert_equal 'ActiveMerchant::Billing::ExactGateway', @g.send(:gateway_class).name
  end

  def get_gateway
    @g.send(:gateway_class).new(:login => 'aou',
                                :password => 'aoeu')
  end

  def test_order_id
    i = mock(:unique_for_paypal => 'something')
    p = mock(:id => 321)
    @g.invoice = i
    @g.payment = p
    Time.stubs(:now).returns('now')
    assert_equal "something-00000321now", @g.order_id
  end

  def test_request_parameters_for_add_customer_data
    i = mock('invoice',
             :description_for_paypal => 'description',
             :customer_name => 'customer name')
    p = mock('payment',
             :ip => '127.0.0.1')
    @g.invoice = i
    @g.payment = p
    @g.expects(:order_id).returns 'order_id'
    billing = BillingAddress.new(:email => 'test@example.com')
    credit_card = mock('credit_card')
    cc, options = @g.send(:request_parameters, [credit_card, billing])
    gateway = get_gateway
    xml = mock('xml')
    xml.expects(:tag!).with('Customer_Ref', 'customer name')
    xml.expects(:tag!).with('Client_IP', '127.0.0.1')
    xml.expects(:tag!).with('Client_Email', 'test@example.com')
    gateway.send(:add_customer_data, xml, options)
  end

  def test_request_parameters_for_add_invoice
    i = mock('invoice',
             :description_for_paypal => 'description',
             :customer_name => 'customer name')
    p = mock('payment',
             :ip => '127.0.0.1')
    @g.invoice = i
    @g.payment = p
    @g.expects(:order_id).returns 'order_id'
    billing = BillingAddress.new(:email => 'test@example.com')
    credit_card = mock('credit_card')
    cc, options = @g.send(:request_parameters, [credit_card, billing])
    gateway = get_gateway
    xml = mock('xml')
    xml.expects(:tag!).with('Reference_No', 'order_id')
    xml.expects(:tag!).with('Reference_3', 'description')
    gateway.send(:add_invoice, xml, options)
  end

  def test_form_partial
    assert_equal 'online_payments/exact_form', @g.form_partial
  end

  def test_supported_cardtypes
    assert_equal ['visa', 'master', 'american_express', 'jcb', 'discover'], @g.supported_cardtypes
  end

  def test_complete_purchase_bad_state
    payment = mock
    payment.expects(:clear_payment!).raises(Sage::BusinessLogic::Exception::CantPerformEventException.new(stub_everything(:id => 1), :clear_payment))
    payment.expects(:error_details=)
    payment.expects(:fail!)
    @g.payment = payment
    @g.stubs(:trace_payment_request)
    @g.stubs(:validate_payment_data!)
    assert_raises(Sage::BusinessLogic::Exception::CantPerformEventException) do
      @g.complete_purchase(nil, nil, nil)
    end
  end

  def test_complete_purchase_good
    payment = mock(:clear_payment! => nil)
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    request_params = mock('request_params')
    credit_card = mock('card')
    @g.stubs(:validate_payment_data!)
    @g.expects(:request_parameters).at_least_once.with(request_params).returns([credit_card, 'params'])
    gateway = mock
    @g.expects(:gateway).returns(gateway)
    response = mock(:success? => true, :params => { 'token' => 'the token' })
    gateway.expects(:purchase).with(1000, credit_card, 'params').returns(response)
    payment.expects(:gateway_token=).with('the token')
    payment.expects(:cleared!)
    @g.complete_purchase(nil, nil, request_params)
  end

  def test_complete_purchase_bad
    payment = mock(:clear_payment! => nil)
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    request_params = mock('request_params')
    credit_card = mock('card')
    @g.stubs(:validate_payment_data!)
    @g.expects(:request_parameters).at_least_once.with(request_params).returns([credit_card, 'params'])
    gateway = mock
    @g.expects(:gateway).returns(gateway)
    response = mock(:success? => false)
    gateway.expects(:purchase).with(1000, credit_card, 'params').returns(response)
    payment.expects(:error_details=)
    payment.expects(:fail!)
    @g.complete_purchase(nil, nil, request_params)
  end

  def test_complete_purchase_fatal
    payment = mock(:clear_payment! => nil)
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    request_params = mock('request_params')
    credit_card = mock('card')
    @g.stubs(:validate_payment_data!)
    @g.expects(:request_parameters).at_least_once.with(request_params).returns([credit_card, 'params'])
    gateway = mock
    @g.expects(:gateway).returns(gateway)
    gateway.expects(:purchase).with(1000, credit_card, 'params').raises('something')
    payment.expects(:error_details=)
    payment.expects(:fail!)
    assert_raises(RuntimeError) do
      @g.complete_purchase(nil, nil, request_params)
    end
  end
end
