require File.dirname(__FILE__) + '/../test_helper'

class BeanStreamInteracGatewayTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

  def setup
    @g = BeanStreamInteracGateway.new
    @g.stubs(:logger).returns(stub_everything)
  end

	def test_display_recipient_name
		#make sure there is a description of the gateway for recipient of the invoice
		assert_not_nil BeanStreamInteracGateway.display_recipient_name
  end

  def test_handle_invoice
    ug = BeanStreamUserGateway.new(:currency => 'CAD')
    assert @g.handle_invoice?(mock(:currency => 'CAD', :user_gateway => ug))
    assert !@g.handle_invoice?(mock(:currency => 'USD', :user_gateway => ug))
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
    assert_equal 'ActiveMerchant::Billing::BeanstreamInteracGateway', @g.send(:gateway_class).name
  end

  def get_gateway
    @g.send(:gateway_class).new(:login => 'oeu',
                         :user => 'aou',
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

  def test_request_parameters_for_add_invoice
    @g.expects(:order_id).returns 'order_id'
    billing = BillingAddress.new(:email => 'email@test.com')
    i = mock('invoice',
            :gst => 10.0,
            :pst => 4.2,
            :subtotal_amount => 32.2,
            :description_for_paypal => 'description')
    @g.invoice = i
    @g.stubs(:amount_as_cents).returns 12345
    options = @g.send(:request_parameters, [billing])
    gateway = get_gateway
    post = {}
    gateway.send(:add_invoice, post, *options)
    assert_equal 'order_id', post[:trnOrderNumber]
    assert_equal '32.20', post[:ordItemPrice]
    assert_equal '10.00', post[:ordTax1Price]
    assert_equal '4.20', post[:ordTax2Price]
    assert_equal 'description', post[:ref1]
  end

  def test_request_parameters_for_add_address
    @g.expects(:order_id).returns 'order_id'
    i = mock('invoice',
            :gst => 10.0,
            :pst => 4.2,
            :subtotal_amount => 99.8,
            :description_for_paypal => 'description')
    @g.invoice = i
    @g.stubs(:amount_as_cents).returns 12345
    billing = BillingAddress.new(:name => 'Darrick Wiebe',
                                 :phone => '416-555-1212',
                                 :email => 'email@test.com',
                                 :address1 => 'addr1',
                                 :address2 => 'addr2',
                                 :city => 'Toronto',
                                 :state => 'ON',
                                 :zip => 'M6J 3C9',
                                 :country => 'CA')
    credit_card = mock('credit_card')
    options, _ = @g.send(:request_parameters, [billing])
    gateway = get_gateway
    hash = {}
    gateway.send(:add_address, hash, options)
    assert_equal 'Darrick Wiebe', hash[:ordName]
    assert_equal 'email@test.com', hash[:ordEmailAddress]
    assert_equal '416-555-1212', hash[:ordPhoneNumber]
    assert_equal 'addr1', hash[:ordAddress1]
    assert_equal 'addr2', hash[:ordAddress2]
    assert_equal 'Toronto', hash[:ordCity]
    assert_equal 'ON', hash[:ordProvince]
    assert_equal 'M6J 3C9', hash[:ordPostalCode]
    assert_equal 'CA', hash[:ordCountry]
  end

  def test_form_partial
    assert_equal 'online_payments/beanstream_interac_form', @g.form_partial
  end

  def test_complete_purchase_bad_state
    controller = mock('controller', :beanstream_interac_response_urls => { :approved_url => 'approved_url', :declined_url => 'declined_url' })
    payment = mock('payment')
    payment.expects(:clear_payment!).raises(Sage::BusinessLogic::Exception::CantPerformEventException.new(stub_everything(:id => 1), :clear_payment))
    payment.expects(:error_details=)
    payment.expects(:fail!)
    @g.payment = payment
    @g.stubs(:trace_payment_request)
    @g.stubs(:validate_payment_data!)
    assert_raises(Sage::BusinessLogic::Exception::CantPerformEventException) do
      @g.complete_purchase(controller, nil, nil)
    end
  end

  def test_complete_purchase_good
    controller = mock('controller', :beanstream_interac_response_urls => { :approved_url => 'approved_url', :declined_url => 'declined_url' })
    payment = mock('payment')
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    credit_card = mock('card')
    @g.stubs(:validate_payment_data!)
    @g.expects(:request_parameters).at_least_once.with([]).returns([credit_card, 'params'])
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock('response', :success? => true)
    gateway.expects(:purchase).with(1000, credit_card, 'params').returns(response)
    payment.expects(:gateway_token=).never
    payment.expects(:clear_payment!)
    payment.expects(:cleared!).never
    @g.complete_purchase(controller, nil, [])
  end

  def test_complete_purchase_bad
    controller = mock('controller', :beanstream_interac_response_urls => { :approved_url => 'approved_url', :declined_url => 'declined_url' })
    payment = mock('payment')
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    credit_card = mock('card')
    @g.stubs(:validate_payment_data!)
    @g.expects(:request_parameters).at_least_once.with([]).returns([credit_card, 'params'])
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock(:success? => false)
    gateway.expects(:purchase).with(1000, credit_card, 'params').returns(response)
    payment.expects(:error_details=)
    payment.expects(:clear_payment!)
    payment.expects(:fail!)
    @g.complete_purchase(controller, nil, [])
  end

  def test_complete_purchase_fatal
    controller = mock('controller', :beanstream_interac_response_urls => { :approved_url => 'approved_url', :declined_url => 'declined_url' })
    payment = mock('payment')
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    credit_card = mock('card')
    @g.stubs(:validate_payment_data!)
    @g.expects(:request_parameters).at_least_once.with([]).returns([credit_card, 'params'])
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    gateway.expects(:purchase).with(1000, credit_card, 'params').raises('something')
    payment.expects(:error_details=)
    payment.expects(:clear_payment!)
    payment.expects(:fail!)
    assert_raises(RuntimeError) do
      @g.complete_purchase(controller, nil, [])
    end
  end

  def test_process_gateway_result_no_data
    request = mock('controller_request')
    request.expects(:raw_post).returns(nil)
    request.expects(:query_string).returns(nil)
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock('gateway_response')
    gateway.expects(:confirm).with(nil).returns(response)
    response.expects(:success?).returns(false)
    @g.payment = payment = mock('payment')
    payment.expects(:error_details=)
    payment.expects(:fail!)
    
    assert_equal response, @g.process_gateway_result(request)
  end
  
  def test_process_gateway_result_success
    request = mock('controller_request')
    request.expects(:raw_post).returns('abc=123&def=321')
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock('gateway_response')
    gateway.expects(:confirm).with('abc=123&def=321').returns(response)
    response.expects(:success?).returns(true)
    @g.payment = payment = mock('payment')
    payment.expects(:gateway_token=).with('the token')
    response.expects(:params).returns 'token' => 'the token'
    payment.expects(:cleared!)
    
    assert_equal response, @g.process_gateway_result(request)
  end
  
  def test_process_gateway_result_failure
    request = mock('controller_request')
    request.expects(:raw_post).returns(nil)
    request.expects(:query_string).returns('abc=123&def=321')
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock('gateway_response')
    gateway.expects(:confirm).with('abc=123&def=321').returns(response)
    response.expects(:success?).returns(false)
    @g.payment = payment = mock('payment')
    payment.expects(:error_details=)
    payment.expects(:fail!)
    
    assert_equal response, @g.process_gateway_result(request)
  end
end
