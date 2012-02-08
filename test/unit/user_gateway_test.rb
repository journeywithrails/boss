require File.dirname(__FILE__) + '/../test_helper'

class UserGatewayTest < ActiveSupport::TestCase
  fixtures :users
  
  def test_to_select
    assert(UserGateway.to_select.is_a?(Array))
  end

  def test_user_gateways
    assert(UserGateway.user_gateways.is_a?(Hash))
  end

  def test_new_polymorphic
    assert(UserGateway.new_polymorphic(:gateway_name => 'beanstream').is_a?(BeanStreamUserGateway))
  end

  def test_set_with_no_params
    user = mock('user')
    gateways = []
    TornadoGateway.expects(:active_gateways).never
    UserGateway.set(user, nil)
  end

  def test_set_with_valid_params
    user = User.find(:first)
    params = { 'beanstream' => { :merchant_id => 'a', :login => 'b', :password => 'c', :currency => 'CAD' } }
    TornadoGateway.expects(:active_gateways).returns([BeanStreamGateway, SageSbsGateway])
    UserGateway.expects(:remove).with(user, 'sage_sbs')
    UserGateway.expects(:add).with do |_user, user_gateway| 
      break false unless _user == user
      user_gateway.is_a?(BeanStreamUserGateway)
    end
    result = UserGateway.set(user, params)
    assert_equal 1, result.length
    assert_equal BeanStreamUserGateway, result.first.class
    assert_equal [], result.first.errors.full_messages
  end

  def test_remove
    UserGateway.expects(:delete_all).with(['user_id = ? and gateway_name = ?', 3, 'beanstream'])
    user = mock('user', :id => 3)
    UserGateway.remove(user, 'beanstream')
  end

  def test_add
    gateways = []
    user = mock('user', :user_gateways => gateways)
    UserGateway.expects(:remove).with(user, 'beanstream')
    gateway = BeanStreamGateway.new
    UserGateway.add(user, gateway)
    assert_equal [gateway], gateways
  end

  def test_set_with_invalid_params
    user = User.find(:first)
    params = { 'beanstream' => { :merchant_id => nil, :login => 'b', :password => 'c', :currency => 'XOX'} }
    TornadoGateway.expects(:active_gateways).returns([BeanStreamGateway, SageSbsGateway])
    UserGateway.expects(:remove).with(user, 'sage_sbs')
    UserGateway.expects(:add).never
    result = UserGateway.set(user, params)
    assert_equal 1, result.length
    assert_equal BeanStreamUserGateway, result.first.class
    assert_equal ["Merchant can't be blank", "Currency is not included in the list"].sort, result.first.errors.full_messages.sort
  end

  def test_form_partial
    assert_equal 'user_gateways/beanstream_form', BeanStreamUserGateway.new(:gateway_name => 'beanstream', :currency => 'CAD').form_partial
  end

  def test_payment_url
    inv = mock('invoice')
    inv.stubs(:create_access_key).returns('key') 
    assert_match %r{https?://[^/]+/invoices/key/online_payments/beanstream}, BeanStreamUserGateway.new(:gateway_name => 'beanstream', :currency => 'CAD').payment_url(inv)
  end

  def test_paypal_payment_url
    inv = mock('invoice')
    inv.stubs(:unique).returns('unique')
    inv.stubs(:total_amount).returns('123')
    inv.stubs(:currency).returns('CAD')
    assert_equal "https://www.paypal.com/webscr?cmd=_xclick&amp;business=email&amp;item_name=Invoice_unique&amp;amount=123&amp;currency_code=CAD", PaypalUserGateway.new(:email => 'email').payment_url(inv)
  end
  
  def test_activate_user_gateway
    g = UserGateway.new_polymorphic({:gateway_name => 'sage_sbs'})
    u = User.find(users(:basic_user))
    
    #TODO: test with user that has existing user_gateway.
    #assert_equal 1, user.user_gateways.count
    assert g.active?, 'User gateway should be active by default'
    g.active = false
    deny g.active?, 'Could not set user gateway inactive'
    deny g.set_active, 'set_active should not save invalid user_gateway'

    g.merchant_id = '123' #required to pass validity checks
    g.merchant_key = 'abc'
    g.currency = 'CAD'
    g.user = u
    
    assert g.set_active, 'set_active should save user_gateway'
    assert_equal 1, u.user_gateways.count, 'There should be one user gateway.'
    assert g.active?, 'User gateway did not become active'
  end

  def test_currency_inclusion_for_sage
    g = UserGateway.new_polymorphic({:gateway_name => 'sage_sbs'})
    u = User.find(users(:basic_user))
    g.merchant_id = '123' #required to pass validity checks
    g.merchant_key = 'abc'
    g.currency = 'USD'
    g.user = u
    assert g.valid?
    g.currency = 'BOX'
    deny g.valid?
  end
  
  def test_user_gateway_digest
    g1 = SageSbsUserGateway.new
    g1.gateway_name = 'sage_sbs'
    
    g2 = UserGateway.new_polymorphic({:gateway_name => 'sage_sbs'})
    assert_equal g1.digest, g2.digest
    
    g1.merchant_id = '123'
    assert_not_equal g1.digest, g2.digest
  end
  
  def test_user_gateway_digest_same_for_different_attributes
    g1 = UserGateway.new_polymorphic({:gateway_name => 'sage_sbs', :merchant_id => '123', :merchant_key => 'abc', :active => true})
    
    g2 = UserGateway.new_polymorphic({:gateway_name => 'sage_sbs', :merchant_id => '123', :merchant_key => 'abc', :active => true})
    assert_equal g1.digest, g2.digest, 'Initial gateway state should be the same'

    #Change active flag on one; hash should still be the same.
    g2.active = false
    assert_equal g1.digest, g2.digest, 'Inactive gateway should be the same as active gateway'

    #A saved record has an id; hash should still be the same.
    g1.save(false)
    assert_equal g1.digest, g2.digest, 'Saved gateway should be the same as unsaved gateway'
    
    #Sanity check, should be different.
    g1.merchant_key = 'changed'
    assert_not_equal g1.digest, g2.digest, 'Gateway with changed info should have different hash'
  end

  def test_supports_currency?
    p = PaypalUserGateway.new
    assert p.supports_currency?('USD')
    deny p.supports_currency?('SFR')
    s = SageSbsUserGateway.new(:currency => 'SFR')
    deny s.supports_currency?('USD')
    deny s.supports_currency?('CAD')
    deny s.supports_currency?('SFR')
    s = SageSbsUserGateway.new(:currency => 'USD')
    assert s.supports_currency?('USD')
    deny s.supports_currency?('CAD')
    deny s.supports_currency?('SFR')
  end

  def test_valid_for?
    p = PaypalUserGateway.new
    assert p.valid_for?('CAD', :paypal)
  end

  def test_valid_for_nil?
    p = PaypalUserGateway.new
    deny p.valid_for?('ZZZ', :paypal)
  end

  def test_handle_invoice?
    p = PaypalUserGateway.new
    i = mock('invoice')
    PaypalGateway.any_instance.expects(:handle_invoice?).with(i).returns(:result)
    assert_equal :result, p.handle_invoice?(i)
  end

  def test_identity_attributes
    s = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs', :currency => 'USD')
    expected = {
      'gateway_name' => 'sage_sbs',
      'type' => 'SageSbsUserGateway',
      'currency' => 'USD'
    }
    expected.each do |name, value|
      assert_equal value, s.identity_attributes[name], "expected #{ expected.inspect }\n got #{ s.identity_attributes.inspect }"
    end
    s.identity_attributes.reject { |k, v| expected.keys.include?(k) }.each do |name, value|
      assert_nil value, "#{ name } should be nil"
    end
  end

  def test_existing_copy_no_user
    s = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs', :currency => 'USD')
    assert_nil s.existing_copy
  end

  def test_existing_copy_with_user_none
    u = users(:basic_user)
    s = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs', :currency => 'USD')
    u.user_gateways << s
    assert_nil s.existing_copy
  end
  
  def test_existing_copy_with_user_exists
    u = users(:basic_user)
    existing = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs', :currency => 'USD', :merchant_id => 'abc', :merchant_key => '123')
    u.user_gateways << existing
    existing.save!
    s = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs', :currency => 'USD', :merchant_id => 'abc', :merchant_key => '123')
    s.user = u
    assert_equal existing, s.existing_copy
  end
end
