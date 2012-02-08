require File.dirname(__FILE__) + '/../test_helper'

class BeanStreamGatewayTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

  def setup
    @g = BeanStreamGateway.new
    @g.stubs(:logger).returns(stub_everything)
  end

	def test_display_recipient_name
		#make sure there is a description of the gateway for recipient of the invoice
		assert_not_nil BeanStreamGateway.display_recipient_name
  end

  def test_handle_invoice
    ug = BeanStreamUserGateway.new(:currency => 'CAD')
    assert @g.handle_invoice?(mock(:currency => 'CAD', :user_gateway => ug))
    assert !@g.handle_invoice?(mock(:currency => 'USD', :user_gateway => ug))

    ug = BeanStreamUserGateway.new(:currency => 'USD')
    assert @g.handle_invoice?(mock(:currency => 'USD', :user_gateway => ug))
    assert !@g.handle_invoice?(mock(:currency => 'CAD', :user_gateway => ug))
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
    assert_equal 'ActiveMerchant::Billing::BeanstreamGateway', @g.send(:gateway_class).name
  end

  def get_gateway
    @g.send(:gateway_class).new(:merchant_id => 'oeu',
                         :login => 'aou',
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
            :subtotal_amount => 123.45,
            :tax1 => 10.0,
            :tax2 => 4.2,
            :description_for_paypal => 'description')
    @g.invoice = i
    credit_card = mock('credit_card')
    cc, options = @g.send(:request_parameters, [credit_card, billing])
 
    assert_equal(credit_card, cc)
    gateway = get_gateway
    hash = {}
    gateway.send(:add_invoice, hash, options)
    assert_equal "123.45", hash[:ordItemPrice]
    assert_equal "10.00", hash[:ordTax1Price]
    assert_equal "4.20", hash[:ordTax2Price]
    assert_equal "0.00", hash[:ordShippingPrice]
    assert_equal "order_id", hash[:trnOrderNumber]
    assert_equal "description", hash[:ref1]
    assert_nil hash[:trnComments]
  end

  def test_request_parameters_for_add_address
    @g.expects(:order_id).returns 'order_id'
    i = mock('invoice',
            :subtotal_amount => 123.45,
            :tax1 => 10.0,
            :tax2 => 4.2,
            :description_for_paypal => 'description')
    @g.invoice = i
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
    cc, options = @g.send(:request_parameters, [credit_card, billing])
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
    assert_equal 'online_payments/beanstream_form', @g.form_partial
  end

  def test_supported_cardtypes
    assert_equal ['visa', 'master', 'american_express'], @g.supported_cardtypes
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

