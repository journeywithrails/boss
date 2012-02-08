require File.dirname(__FILE__) + '/../test_helper'

class SageSbsGatewayTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

  def setup
    @g = SageSbsGateway.new
    @g.stubs(:logger).returns(stub_everything)
  end

  def test_display_name
    assert_equal 'Sage Card Services (US Dollar)', SageSbsGateway.display_name
  end

  def test_find_by_name
    assert_equal SageSbsGateway, TornadoGateway.find_by_name('sage_sbs')
  end

  def test_single_call
    assert SageSbsGateway.single_call?
  end

  def test_position
    assert SageSbsGateway.position.is_a?(Numeric)
  end

  def test_in_gateways
    assert TornadoGateway.gateways.include?(SageSbsGateway)
  end

  def test_handle_invoice_usd
    invoice = mock
    invoice.expects(:currency).returns('USD')
    user_gateway = mock(:currency => 'USD')
    invoice.expects(:user_gateway).with('sage_sbs').returns(user_gateway)
    assert @g.handle_invoice?(invoice)
  end

  def test_handle_invoice_cad
    invoice = mock
    invoice.expects(:currency).returns('CAD')
    user_gateway = mock(:currency => 'USD')
    invoice.expects(:user_gateway).with('sage_sbs').returns(user_gateway)
    deny @g.handle_invoice?(invoice)
  end

  def test_initialize_payment_data
    card_params = { }
    address_params = { }
    params = { :card => card_params, :billing_address => address_params }
    card, address, nothing = @g.initialize_payment_data(params)
    assert(card.class == ActiveMerchant::Billing::CreditCard)
    assert(address.class == BillingAddress)
    assert_equal [:address1, :city, :state, :zip, :country, :phone, :email], address.validate_fields
    assert_nil nothing
  end

  def test_trace_payment_request
    params = { :card => { }, :billing_address => { } }
    pd = @g.initialize_payment_data(params)
    @g.invoice = mock('invoice', :subtotal_amount => 1.00, :total_taxes_as_cents => 5, :description_for_paypal => 'desc')
    @g.stubs(:amount_as_cents).returns(100)
    @g.stubs(:order_id).returns('id')
    #just ensure it runs
    @g.send(:trace_payment_request, pd)
  end

  def test_payment_data_types
    assert_equal [ActiveMerchant::Billing::CreditCard, BillingAddress], @g.send(:payment_data_types)
  end

  def test_gateway_class
    assert_equal ActiveMerchant::Billing::SageBankcardGateway, @g.send(:gateway_class)
  end

  def test_request_parameters
    invoice = mock('invoice', :subtotal_amount => 1.0, :total_taxes_as_cents => 5, :description_for_paypal => 'test_inv')
    billing_address = mock('billing address', :email => 'a@b.com')
    @g.stubs(:order_id).returns('order_id')
    @g.invoice = invoice
    pd = [:credit_card, billing_address]
    response = @g.send(:request_parameters, pd)
    assert_equal(response, [:credit_card, {
      :order_id => 'order_id',
      :billing_address => billing_address,
      :email => 'a@b.com',
      :sub_total => Cents.new(:dollars => 1.0),
      :tax => Cents.new(:cents => 5),
      :addenda => 'test_inv'}])
  end
end
