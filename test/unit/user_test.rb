require File.dirname(__FILE__) + '/../test_helper'

Longest_email = 100
Shortest_email  = 3
    
class UserTest < Test::Unit::TestCase
  fixtures :users, :billers, :bookkeepers, :bookkeeping_contracts
  
  def setup
    ::AppConfig.activate_users = false
    Invoice.connection.execute('delete from invoices')
  end

  def teardown
  end
  
  def test_should_not_allow_signup_without_accepting_tos
    assert_no_difference 'User.count' do
      user = create_user(:terms_of_service => '0')
    end
    assert_no_difference 'User.count' do
      user = create_user(:terms_of_service => nil)
    end   
    assert_difference 'User.count' do
      user = create_user(:terms_of_service => '1')
    end
  end
  
  def test_should_allow_valid_email_addresses
    ['valid@example.com',
     'valid@test.example.com',
     'valid+valid123@test.example.com',
     'valid_valid123@test.example.com',
     'valid-valid+123@test.example.co.uk',
     'valid-valid+1.23@test.example.com.au',
     'valid@example.co.uk',
     'v@example.com',
     'valid@example.ca',
     'valid123.456@example.org',
    'valid123.456@adomain.gov',
     'valid123.456@example.travel',
     'valid123.456@example.museum',
     'valid123.456@example.asia',
     'vtest@mydomain.edu',
     'vtest@mydomain.com.cn',
     'test@example.mobi',
     'valid@example.info'].each do |email|
      p = create_user(:email => email)
      assert_nil p.errors.on(:email), email + " should be valid"
    end
  end


  def test_should_not_allow_invalid_email_addresses
    ['_invalid@example.com',
     'invalid@example-com',
     'invalid_@example.com',
     'invalid-@example.com',
     '.invalid@example.com',
     'invalid.@example.com',
     'invalid@example.com.',
     'invalid@example.com_',
     'invalid@example.com-',
     'invalid-example.com',
     'invalid@example.b#r.com',
     'invalid@example.c',
     'invali d@example.com',
     'invalidexample.com',
     'invalid@e.',     
     'rob@.c',
     'invalid@example.'].each do |email|
      p = create_user(:email => email)  
      assert p.errors.on(:email), email + " should be invalid"
    end
  end  

   
  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end
    
  def save_fails(p, email = '')
    assert !p.valid?, " validating #{email}"
    assert !p.save
    assert p.errors.on(:email)
  end

  def test_should_require_sage_username
    assert_no_difference 'User.count' do
      u = create_user(:sage_username => nil)
      assert u.errors.on(:sage_username)
    end
  end
  
  #test if invalid email addresses are caught
  def test_should_allow_long_email         
    email_address = ""
    (Longest_email - "@123.com".length).times do
        email_address << "a"
    end
    #add the @ part to the email address
    email_address << "@123.com"
    u = create_user(:email => email_address)
    assert_nil u.errors.on(:email)  
    
  end
  

  def test_should_set_remember_token
    users(:basic_user).remember_me
    assert_not_nil users(:basic_user).remember_token
    assert_not_nil users(:basic_user).remember_token_expires_at
    assert users(:basic_user).remember_token?
  end

  def test_should_unset_remember_token
    users(:basic_user).remember_me
    assert_not_nil users(:basic_user).remember_token
    users(:basic_user).forget_me
    assert_nil users(:basic_user).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:basic_user).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:basic_user).remember_token
    assert_not_nil users(:basic_user).remember_token_expires_at
    assert users(:basic_user).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:basic_user).remember_me_until time
    assert_not_nil users(:basic_user).remember_token
    assert_not_nil users(:basic_user).remember_token_expires_at
    assert_equal users(:basic_user).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:basic_user).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:basic_user).remember_token
    assert_not_nil users(:basic_user).remember_token_expires_at
    assert users(:basic_user).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_search_params_by_key
    u = users(:basic_user)
    assert_nil u.searches
    u.set_or_get_search!(:invoices, {:first => 'cool', :second => 'nifty'})
    assert_not_nil u.searches
    assert u.searches.kind_of?(Hash)
    assert_not_nil u.searches[:invoices]
    assert_equal "nifty", u.searches[:invoices][:second]    
  end
  
  def test_should_get_remembered_search_params_by_key
    u = users(:basic_user)
    assert_nil u.searches
    u.set_or_get_search!(:invoices, {:first => 'cool', :second => 'nifty'})

    params = u.set_or_get_search!(:invoices, nil)
    assert_not_nil params
    assert_equal "nifty", params[:second]    

    params = u.set_or_get_search!(:invoices, {})
    assert_not_nil params
    assert_equal "nifty", params[:second]    
  end
  
  def test_should_clear_remembered_search_params_by_key
    u = users(:basic_user)
    assert_nil u.searches
    u.set_or_get_search!(:invoices, {:first => 'cool', :second => 'nifty'})

    params = u.set_or_get_search!(:invoices, nil)
    assert_not_nil params
    assert_equal "nifty", params[:second]    

    params = u.set_or_get_search!(:invoices, {:clear => 'some text', :any_other_key => 'stuff'})
    assert params.empty?
  end

  def test_can_change_email
    u = users(:basic_user)
    assert_equal "basic_user@billingboss.com", u.email 
    u.email = "someotheremail@billingboss.com"
    assert u.save
    assert_equal "someotheremail@billingboss.com", u.email 
  end
   
    ##############  User Story trac #34 ####################################
  def test_should_have_preferences
    u = users(:basic_user)
    assert_nil u.settings['arbitrary']
    u.settings['arbitrary'] = 'the arbitrary setting'
    u.reload
    assert_equal 'the arbitrary setting', u.settings['arbitrary']
  end
  
  ### trac ticket #112 Default discount_before_tax to true
  def test_should_default_discount_before_tax_to_true
    u = User.create
    assert_equal true, u.profile.discount_before_tax
  end

  def test_should_generate_next_auto_number
    u = users(:basic_user)
    assert u.invoices.empty?
    assert 1, u.generate_next_auto_number
  end
  
  ############### User Story trac #218 ########################
  def test_should_create_bookkeeper_user
    u = User.create
    assert u.bookkeeper.nil?
    deny u.biller.nil?
    
    bk = Bookkeeper.create
    bi = Biller.create
    u.bookkeeper = bk
    u.biller = bi
    
    u.save
  end
 
  def test_should_not_assign_bookkeeping_role_for_same_user
    u = User.find(users(:bookkeeper_user))
    assert_raise(Sage::BusinessLogic::Exception::RolesException) do
      u.has_role('bookkeeping', u)
    end
  end

  def test_non_bookkeeper_should_not_have_bookkeeper_role
    u = User.find(users(:wants_bookkeeper_user))
    u_other = User.find(users(:doesnt_want_bookkeeper_user))
    role = u.has_role?('bookkeeping')
    role_for_u_other = u.has_role?('bookkeeping', u_other)
    deny role, 'user should not have bookkeeping role'
    deny role_for_u_other, 'user should not have bookkeeping role on other user'
  end
  
  def test_should_not_assign_bookkeeping_role_to_non_bookkeeper
    u = User.find(users(:wants_bookkeeper_user))
    u_other = User.find(users(:doesnt_want_bookkeeper_user))
    assert_raise(Sage::BusinessLogic::Exception::RolesException) do
      u.has_role('bookkeeping', u_other)
    end
  end
  
  def test_should_assign_bookkeeping_role_to_bookkeeper_for_other_user
    u = User.find(users(:bookkeeper_user))
    u_other = User.find(users(:wants_bookkeeper_user))
    
    assert u.bookkeeper

    role = u.has_role?('bookkeeping')
    role_for_u_other = u.has_role?('bookkeeping', u_other)
    deny role, 'bookkeeper should not have bookkeeping role yet'
    deny role_for_u_other, 'bookkeeper should not have bookkeeping role on other user yet'

    assert_raise(Sage::BusinessLogic::Exception::RolesException) do
      #association does not exist yet.
      u.has_role('bookkeeping', u_other)
    end
    
    u.bookkeeper.bookkeeping_contracts.create(:bookkeeping_client => u_other.biller)
    u.has_role('bookkeeping', u_other)

    assert u.has_role?('bookkeeping'), 'bookkeeper should have bookkeeping role'
    assert u.has_role?('bookkeeping', u_other), 'bookkeeper should have bookkeeping role on other user'

    u.has_no_role('bookkeeping', u_other)

    deny u.has_role?('bookkeeping'), 'bookkeeping role should have been revoked'
    deny u.has_role?('bookkeeping', u_other), 'bookkeeping role should have been revoked for bookkeeper on other user'
  end

  def test_should_assign_unknown_role_to_bookkeeper_for_other_user
    u = User.find(users(:bookkeeper_user))
    u_other = User.find(users(:wants_bookkeeper_user))

    deny u.has_role?('some_role'), 'bookkeeper should not have some_role yet'
    deny u.has_role?('some_role', u_other), 'bookkeeper should not have some_role on other user yet'
    
    u.has_role('some_role', u_other)

    assert u.has_role?('some_role'), 'bookkeeper should have some_role'
    assert u.has_role?('some_role', u_other), 'bookkeeper should have some_role on other user'

    u.has_no_role('some_role', u_other)

    deny u.has_role?('some_role'), 'some_role should have been revoked'
    deny u.has_role?('some_role', u_other), 'some_role should have been revoked for bookkeeper on other user'
  end

  def test_user_returns_name_that_is_company_name_or_email
    u1 = User.new
    u1.email = "bob@bob.com"
    p1 = mock()
    p1.expects(:company_name).at_least_once.returns("nifty")
    u1.expects(:profile).at_least_once.returns(p1)
    assert u1.name == 'nifty'
    
    u2 = User.new
    u2.email = "bob@bob.com"
    p2 = mock()
    p2.expects(:company_name).at_least_once.returns(nil)
    u2.expects(:profile).at_least_once.returns(p2)
    assert u2.name == 'bob@bob.com'
    
  end

  def test_inclusion_of_heard_from_in_list
    
    u1 = User.new
    u1.sage_username = "rac_a"
    u1.email = "rac_a@billingboss.com"
    
    u1.terms_of_service = "1"
    u1.heard_from = "friend_or_acquaintance"
    assert u1.valid?
    
    u2 = User.new
    u2.sage_username = "rac_b"
    u2.email = "rac_b@billingboss.com"
    u2.terms_of_service = "1"
    u2.heard_from = "bob"
    deny u2.valid?
    
    u3 = User.new
    u3.sage_username = "rac_c"
    u3.email = "rac_c@billingboss.com"
    u3.terms_of_service = "1"
    u3.heard_from = ""
    deny u3.valid?

    u4 = User.new
    u4.sage_username = "rac_d"
    u4.email = "rac_d@billingboss.com"
    u4.terms_of_service = "1"
    u4.heard_from = nil
    assert u4.valid?

  end

  def test_profile_required_for_new_rac_user
    u1 = User.new
    u1.sage_username = "rac_a"
    u1.terms_of_service = "1"
    u1.heard_from = "friend_or_acquaintance"
    u1.signup_type = 'soho'
    assert u1.profile.valid?
    
    u1.signup_type = 'rac'
    deny u1.profile.valid?

    u1.profile.expects(:is_complete?).at_least_once.returns(true)
    assert u1.profile.valid?

  end

  def test_profile_not_required_for_existing_rac_user
    u1 = User.new
    u1.terms_of_service = "1"
    u1.heard_from = "friend_or_acquaintance"
    u1.signup_type = 'rac'
    u1.save(false)
    assert u1.profile.valid?
  end
  
  def test_singup_key
    u = User.new
    deny u.is_signup_key(12345)
    assert u.is_signup_key(100524)
  end

  def test_user_gateway_no_params
    u = User.new
    ugs = u.user_gateways
    ugs.expects(:find).with(:first, :conditions => { :active => true }).returns(:result)
    assert_equal :result, u.user_gateway
  end

  def test_user_gateway_create_new
    u = User.new
    ugs = u.user_gateways
    ugs.expects(:find_by_gateway_name).with('sage_sbs').returns(nil)
    UserGateway.expects(:new_polymorphic).with(:gateway_name => 'sage_sbs').returns(:a_new_user_gateway)
    assert_equal :a_new_user_gateway, u.user_gateway('sage_sbs', true)
  end

  def test_user_gateway_found
    u = User.new
    ugs = u.user_gateways
    ugs.expects(:find_by_gateway_name).with('sage_sbs').returns(:result)
    assert_equal :result, u.user_gateway('sage_sbs')
  end

  def test_user_gateway_not_found
    u = User.new
    ugs = u.user_gateways
    ugs.expects(:find_by_gateway_name).with('sage_sbs').returns(nil)
    assert_nil u.user_gateway('sage_sbs', false)
  end

  def test_payment_types_for_cad_with_no_gateways
    u = User.new
    assert_equal [], u.payment_types('CAD')
  end

  def test_payment_types_for_cad_with_sage_cdn
    u = User.new
    ug = SageSbsUserGateway.new(:currency => 'CAD')
    u.user_gateways << ug
    assert_equal [:visa, :master, :american_express, :discover, :jcb, :diners_club], u.payment_types('CAD')
  end
  
  def test_payment_types_for_usd_with_sage_cdn
    u = User.new
    ug = SageSbsUserGateway.new(:currency => 'CAD')
    u.user_gateways << ug
    assert_equal [], u.payment_types('USD')
  end
  
  def test_payment_types_for_sfr_with_sage_cdn
    u = User.new
    ug = SageSbsUserGateway.new(:currency => 'CAD')
    u.user_gateways << ug
    assert_equal [], u.payment_types('sfr')
  end
  
  def test_payment_types_for_cad_with_beanstream
    u = User.new
    ug = BeanStreamUserGateway.new :currency => 'CAD'
    u.user_gateways << ug
    assert_equal [:visa, :master, :american_express], u.payment_types('CAD')
  end
  
  def test_payment_types_for_sfr_with_beanstream
    u = User.new
    ug = BeanStreamUserGateway.new :currency => 'CAD'
    u.user_gateways << ug
    assert_equal [], u.payment_types('SFR')
  end

  def test_payment_types_for_cad_with_beanstream_and_sage_cdn
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageSbsUserGateway.new(:currency => 'CAD')
    assert_equal [:visa, :master, :american_express, :discover, :jcb, :diners_club], u.payment_types('CAD')
  end
  
  def test_payment_types_for_cad_with_beanstream_and_sage_usd
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageSbsUserGateway.new(:currency => 'USD')
    assert_equal [:visa, :master, :american_express], u.payment_types('CAD')
  end
  
  def test_payment_types_for_cad_with_beanstream_and_sage_vcheck
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageVcheckUserGateway.new
    assert_equal [:visa, :master, :american_express], u.payment_types('CAD')
  end
  
  def test_payment_types_for_usd_with_beanstream_and_sage_vcheck
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageVcheckUserGateway.new
    assert_equal [:virtual_check], u.payment_types('USD')
  end
  
  def test_payment_types_for_usd_with_beanstream_and_sage_vcheck_and_sage_usd
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageVcheckUserGateway.new
    u.user_gateways << SageSbsUserGateway.new(:currency => 'USD')
    assert_equal [:virtual_check, :visa, :master, :american_express, :discover, :jcb, :diners_club], u.payment_types('USD')
  end
  
  def test_payment_types_for_usd_with_beanstream_and_sage_vcheck_and_paypal
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageVcheckUserGateway.new
    u.user_gateways << PaypalUserGateway.new
    u.user_gateways << PaypalExpressUserGateway.new
    assert_equal [:virtual_check, :paypal, :paypal_express], u.payment_types('USD')
  end
  
  def test_payment_types_for_jpy_or_sfr_with_beanstream_and_sage_vcheck_and_paypal
    u = User.new
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << SageVcheckUserGateway.new
    u.user_gateways << PaypalUserGateway.new
    u.user_gateways << PaypalExpressUserGateway.new
    assert_equal [:paypal, :paypal_express], u.payment_types('JPY')
    assert_equal [], u.payment_types('SFR')
  end

  def test_gateway_class_for_payment_method_cad_visa
    u = User.new
    u.expects(:user_gateway_for).with('CAD', :visa).returns(BeanStreamUserGateway.new :currency => 'CAD')
    assert_equal BeanStreamGateway, u.gateway_class('CAD', :visa)
  end

  def test_user_gateway_for_cad_visa_with_beanstream_cad
    u = User.new
    bsug = BeanStreamUserGateway.new :currency => 'CAD'
    u.user_gateways << bsug
    assert_equal bsug, u.user_gateway_for('CAD', :visa)
  end
  
  def test_user_gateway_for_usd_visa_with_beanstream_cad
    u = User.new
    bsug = BeanStreamUserGateway.new :currency => 'CAD'
    u.user_gateways << bsug
    assert_nil u.user_gateway_for('USD', :visa)
  end

  def test_user_gateway_for_cad_visa_with_beanstream_usd
    u = User.new
    bsug = BeanStreamUserGateway.new :currency => 'USD'
    u.user_gateways << bsug
    assert_nil u.user_gateway_for('CAD', :visa)
  end
  
  def test_user_gateway_for_usd_visa_with_beanstream_usd
    u = User.new
    bsug = BeanStreamUserGateway.new :currency => 'USD'
    u.user_gateways << bsug
    assert_equal bsug, u.user_gateway_for('USD', :visa)
  end

  def test_user_gateway_for_usd_visa_with_beanstream_cad_and_sage_usd
    u = User.new
    ug = SageSbsUserGateway.new(:currency => 'USD')
    u.user_gateways << BeanStreamUserGateway.new(:currency => 'CAD')
    u.user_gateways << ug
    assert_equal ug, u.user_gateway_for('USD', :visa)
  end

  def test_user_gateways_for
    u = User.new
    sage = SageSbsUserGateway.new(:currency => 'USD')
    paypal = PaypalUserGateway.new
    u.stubs(:user_gateways).returns([sage, paypal])
    assert_equal([sage, paypal], u.user_gateways_for('USD', [:visa, :paypal]))
    assert_equal([paypal], u.user_gateways_for('CAD', [:visa, :paypal]))
    assert_equal([sage], u.user_gateways_for('USD', [:visa, :master]))
    assert_equal([], u.user_gateways_for('CAD', [:other]))
    assert_equal([], u.user_gateways_for('SFR', [:visa, :master]))
  end

  # preferred_language attribute does not actually exist
  def test_find_or_build_simply_customer_no_existing
    customer_attrs = {
      :metadata => { :guid => "C000000000111111111122222222223" },
      :name => "customer name",
      :contact_name => "contact name",
      :preferred_language => "English",
      :simply_guid => "theguid"
    }
    user = users(:basic_user)   
    user.customers.expects(:find).with(:first, :conditions => { :simply_guid => 'theguid' }).returns(nil)
    customer = user.find_or_build_simply_customer(customer_attrs)
    assert_equal 'customer name', customer.name
    assert_equal 'contact name', customer.contact_name
    assert_equal 'theguid', customer.simply_guid
  end
  
  def test_find_or_build_simply_customer_with_existing
    existing = Customer.new
    customer_attrs = {
      :metadata => { :guid => "C000000000111111111122222222223" },
      :name => "customer name",
      :contact_name => "contact name",
      :preferred_language => "English",
      :simply_guid => "theguid"
    }
    user = users(:basic_user)   
    user.customers.expects(:find).with(:first, :conditions => { :simply_guid => 'theguid' }).returns(existing)
    customer = user.find_or_build_simply_customer(customer_attrs)
    assert_equal 'customer name', customer.name
    assert_equal 'contact name', customer.contact_name
    assert_equal 'theguid', customer.simply_guid
    assert_equal existing, customer
  end

  if File.exists?("/home/rails/sageaccountmanager/current/config/database.yml")
  
    def test_register_sage_user_with_legacy_password_bogus_user
      u = User.new
      u.email = "test@x.com"
      u.id = 1
      u.bogus = true
      u.register_sage_user_with_legacy_password!
      assert_nil u.sage_username, "The sage_username should be nil for a bogus user"
    end

    def test_register_sage_user_with_legacy_password_existing_sage_user
      u = User.new({ 
        :bogus => false, 
        :email => 'test@x.com', 
        :terms_of_service => '1',
        :crypted_password => 'password' })    
    
      su = SageUser.new
      su.email = "test@x.com"
      su.username = "sage_username"
      SageUser.stubs(:find).returns(su)  
      SageUser.stubs(:save)  

      u.register_sage_user_with_legacy_password!
      assert_equal "sage_username", u.sage_username, "The sage_username should be 'sage_username'"
    end
  
    def test_register_sage_user_with_legacy_password_create_sage_user
      u = User.new({ 
        :bogus => false, 
        :email => 'test@x.com', 
        :terms_of_service => '1',
        :crypted_password => 'password' })    

      SageUser.stubs(:find).returns(nil)  
      su = SageUser.new
      su.id = 1
      su.email = "test@x.com"
      su.username = "test"    
      SageUser.stubs(:create).returns(su)  

      u.register_sage_user_with_legacy_password!
      assert_equal "test", u.sage_username, "The sage_username should be 'test'"
    end
  
    def test_register_sage_user_with_legacy_password_special_prefix
      u = User.new({ 
        :bogus => false, 
        :email => 'info@domain.name.com', 
        :terms_of_service => '1',
        :crypted_password => 'password' })    

      u.register_sage_user_with_legacy_password!
      assert_equal "domain_name", u.sage_username, "The sage_username should be 'domain_name'"

      su = SageUser.find(:first, :conditions => {:username => u.sage_username})
      assert_not_nil su, "SageUser should not be nil"
    end  

    def test_register_sage_user_with_legacy_password_punctuation
      u = User.new({ 
        :bogus => false, 
        :email => 'punc-tua.ti+on@x.com', 
        :terms_of_service => '1',
        :crypted_password => 'password' })    

      u.register_sage_user_with_legacy_password!
      assert_equal "punc_tua_ti_on", u.sage_username, "The sage_username should be 'punc_tua_ti_on'"

      su = SageUser.find(:first, :conditions => {:username => u.sage_username})
      assert_not_nil su, "SageUser should not be nil"
    end  
  
    def test_register_sage_user_with_legacy_password_create_sage_user_username_exists
      u = User.new({ 
        :bogus => false, 
        :email => 'test@x.com', 
        :terms_of_service => '1',
        :crypted_password => 'password' })    

      SageUser.stubs(:find).returns(nil, true, nil)  
      su = SageUser.new
      su.id = 1
      su.email = "test@x.com"
      su.username = "test"    
      SageUser.stubs(:create).returns(su)  

      u.register_sage_user_with_legacy_password!
      assert_equal "test_2", u.sage_username, "The sage_username should be 'test_2'"
    end 
  end

  protected
    def create_user(options = {})
      User.create({ 
        :sage_username => 'quire', 
        :email => 'quire@example.com', 
        :terms_of_service => '1' }.merge(options))
    end
  
end
