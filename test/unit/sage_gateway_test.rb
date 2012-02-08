
require File.dirname(__FILE__) + '/../test_helper'

class SageGatewayTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

  def setup
    @g = SageGateway.new
    @g.stubs(:logger).returns(stub_everything)
  end

	def test_display_recipient_name
		#make sure there is a description of the gateway for recipient of the invoice
		assert_not_nil SageGateway.display_recipient_name
  end

  def test_handle_invoice
    assert !@g.handle_invoice?(mock(:currency => 'CAD'))
    assert @g.handle_invoice?(mock(:currency => 'USD'))
    assert !@g.handle_invoice?(mock(:currency => 'JPY'))
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
    assert_equal 'ActiveMerchant::Billing::SageVirtualCheckGateway', @g.send(:gateway_class).name
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

  def test_form_partial
    assert_equal 'online_payments/sage_vcheck_form', @g.form_partial
  end

  def test_supported_cardtypes
    assert_equal [], @g.supported_cardtypes
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
    cheque = mock('cheque')
    request_params = mock('request_params')
    @g.expects(:validate_payment_data!).with(request_params)
    @g.expects(:request_parameters).at_least_once.with(request_params).returns([cheque, 'params'])
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock(:success? => true, :params => { 'token' => 'the token' })
    gateway.expects(:purchase).with(1000, cheque, 'params').returns(response)
    payment.expects(:gateway_token=).with('the token')
    payment.expects(:cleared!)
    @g.complete_purchase(nil, nil, request_params)
  end

  def test_complete_purchase_bad
    payment = mock(:clear_payment! => nil)
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    cheque = mock('cheque')
    request_params = mock('request_params')
    @g.expects(:validate_payment_data!).with(request_params)
    @g.expects(:request_parameters).at_least_once.with(request_params).returns([cheque, 'params'])
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    response = mock(:success? => false)
    gateway.expects(:purchase).with(1000, cheque, 'params').returns(response)
    payment.expects(:error_details=)
    payment.expects(:fail!)
    @g.complete_purchase(nil, nil, request_params)
  end

  def test_complete_purchase_fatal
    payment = mock(:clear_payment! => nil)
    @g.payment = payment
    @g.expects(:amount_as_cents).at_least_once.returns 1000
    cheque = mock('cheque')
    request_params = mock('request_params')
    @g.expects(:validate_payment_data!).with(request_params)
    @g.expects(:request_parameters).at_least_once.with(request_params).returns([cheque, 'params'])
    gateway = mock('gateway')
    @g.expects(:gateway).returns(gateway)
    gateway.expects(:purchase).with(1000, cheque, 'params').raises('something')
    payment.expects(:error_details=)
    payment.expects(:fail!)
    assert_raises(RuntimeError) do
      @g.complete_purchase(nil, nil, request_params)
    end
  end
end

class SageGatewayPostParamsTest < ActiveSupport::TestCase
  def setup
    @g = SageGateway.new
    @g.stubs(:logger).returns(stub_everything)
    @g.expects(:order_id).returns 'order_id'
    i = mock('invoice',
            :subtotal_amount => 123.45,
            :total_taxes_as_cents => 1420,
            :description_for_paypal => 'description')
    @g.invoice = i
    check = ActiveMerchant::Billing::Check.new(:first_name => 'Darrick',
                                                :last_name => 'Wiebe',
                                                :routing_number => 'routing',
                                                :account_number => 'account',
                                                :number => 'number',
                                                :account_type => 'checking')
    dob = BirthDate.new(:birth_date => '1977/07/11')
    license = DriversLicense.new(:state => 'AL', :number => '1234')
    ssn = SocialSecurityNumber.new(:number => '123')
    billing = BillingAddress.new(:phone => '416-555-1212',
                                 :fax => '416-555-1211',
                                 :email => 'email@test.com',
                                 :address1 => 'addr1',
                                 :address2 => 'addr2',
                                 :city => 'Toronto',
                                 :state => 'ON',
                                 :zip => 'M6J 3C9',
                                 :country => 'CA')
    customer = SageGateway::Customer.new(:customer_type => 'personal')
    business = SageGateway::Business.new(:federal_tax_number => 'xyz')
    @check, @options = @g.send(:request_parameters, [check, dob, license, ssn, billing, customer, business])
    assert_equal check, @check
    @gateway = @g.send(:gateway_class).new(:merchant_id => 'oeu',
                         :login => 'aou',
                         :password => 'aoeu')
  end

  def test_add_addresses
    hash = {}
    @gateway.send(:add_addresses, hash, @options)
    assert_equal 'email@test.com', hash[:C_email]
    assert_equal '416-555-1212', hash[:C_telephone]
    assert_equal '416-555-1211', hash[:C_fax]
    assert_equal 'addr1', hash[:C_address]
    assert_equal 'Toronto', hash[:C_city]
    assert_equal 'ON', hash[:C_state]
    assert_equal 'M6J 3C9', hash[:C_zip]
    assert_equal 'CA', hash[:C_country]
    assert_equal 8, hash.to_a.length
  end

  def test_add_check
    hash = {}
    @gateway.send(:add_check, hash, @check)
    assert_equal 'Darrick', hash[:C_first_name]
    assert_equal 'Wiebe', hash[:C_last_name]
    assert_equal 'routing', hash[:C_rte]
    assert_equal 'account', hash[:C_acct]
    assert_equal 'number', hash[:C_check_number]
    assert_equal 'DDA', hash[:C_acct_type]
    assert_equal 6, hash.to_a.length
  end

  def test_add_check_customer_data
    hash = {}
    @gateway.send(:add_check_customer_data, hash, @options)
    assert_equal 'WEB', hash[:C_customer_type]
    assert_equal nil, hash[:C_originator_id]
    assert_equal 'description', hash[:T_addenda]
    assert_equal '123', hash[:C_ssn]
    assert_equal 'AL', hash[:C_dl_state_code]
    assert_equal '1234', hash[:C_dl_number]
    assert_equal '07/11/1977', hash[:C_dob]
    # Field was removed...
    #assert_equal 'xyz', hash[:C_ein]
    assert_equal 7, hash.to_a.length
  end

  def test_add_transaction_data
    hash = {}
    #add_addresses is already tested...
    @gateway.expects(:add_addresses).with(hash, @options)
    @gateway.send(:add_transaction_data, hash, 12345, @options)
    assert_equal '123.45', hash[:T_amt]
    assert_equal 'order_id', hash[:T_ordernum]
    assert_equal '14.20', hash[:T_tax]
    assert_equal nil, hash[:T_customer_number]
    assert_equal 4, hash.to_a.length
  end

end
