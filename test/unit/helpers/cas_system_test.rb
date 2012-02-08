require File.dirname(__FILE__) + '/../../test_helper'

require 'user'

class StubController
end

class CasSystemTest < HelperTestCase


  def setup
    StubController.any_instance.stubs(:init_language)
    super
  end

  def test_has_billingboss_user_and_sage_user
    stub_current_user_with_bob; stub_session_with_bob
    assert @controller.logged_in?
    assert @controller.has_billingboss_user?
    assert @controller.has_sage_user?
  end
  
  def test_cas_service_url_default
    GettextLocalize.stubs(:locale).returns(nil)
    assert_equal Sage::Test::Server.billingboss.url + "/stubcontroller/bob",
      @controller.cas_service_url({:controller => 'StubController', :action=>'bob'}),
      "service url should be absolute url to controller/action"
  end
  
  def test_cas_service_url_with_api_token
    stub_api_token
    GettextLocalize.stubs(:locale).returns(nil)
    assert_equal Sage::Test::Server.billingboss.url + "/api/mary/stubcontroller/bob",
      @controller.cas_service_url({:controller => 'StubController', :action=>'bob'}),
      "service url should be absolute url to /api/mary/controller/action"
  end

  def test_cas_service_url_omits_browsal_param
    assert( !(@controller.cas_service_url({:controller => 'StubController', :action=>'bob', :browsal => 'whatever'}) =~ /browsal/),
      "service url should omit browsal param")
  end
  
  def test_cas_service_url_omits_simply_request_param
    assert( !(@controller.cas_service_url({:controller => 'StubController', :action=>'bob', :simply_request => 'whatever'}) =~ /simply_request/),
      "service url should omit simply_request param")
  end
  
  def test_create_user_for_cas_user_builds_and_returns_new_user
    stub_api_token
    user = mock_autocreate_user(false)
    @controller.expects(:session).at_least_once.returns({})
    User.expects(:build_with_sage_username).with({:username => 'bob-the-new-user'}).returns(user)
    assert_equal user, 
      @controller.create_user_for_cas_user('bob-the-new-user', {}), 
      "create_user_for_cas_user should return a newly built user"
  end

  def test_create_user_for_cas_user_builds_and_returns_new_user_with_credit_referral
    stub_api_token
    mock_session = {:referral_code => 'howdy'}
    @controller.expects(:session).at_least_once.returns(mock_session)
    user = mock_autocreate_user(true)
    User.expects(:build_with_sage_username).with({:username => 'bob-the-new-user'}).returns(user)
    assert_equal user, 
      @controller.create_user_for_cas_user('bob-the-new-user', {}), 
      "create_user_for_cas_user should return a newly built user"
    assert_nil mock_session[:referral_code]
  end
  
  def test_user_for_cas_user_finds_existing_user
    # stub_api_token
    mock_session = {}
    existing_user = mock_existing_user
    User.expects(:find_by_sage_username).with('bob-the-new-user').returns(existing_user)
    User.expects(:build_with_sage_username).never
    assert_equal existing_user, 
      @controller.user_for_cas_user('bob-the-new-user', {}), 
      "user_for_cas_user should return existing user"
  end
  
  def test_user_for_cas_user_returns_nil_if_no_user_exists_and_autocreate_is_false
    # stub_api_token
    existing_user = mock_existing_user
    User.expects(:find_by_sage_username).with('bob-the-new-user').returns(nil)
    User.expects(:build_with_sage_username).never
    @controller.expects(:auto_create_user?).returns(false)
    assert_nil @controller.user_for_cas_user('bob-the-new-user', {}), 
      "user_for_cas_user should return existing user"
  end
  
  def test_user_for_cas_user_creates_user_if_no_user_exists_and_autocreate_is_true
    # stub_api_token
    @controller.stubs(:session).returns({})
    existing_user = mock_existing_user
    new_user = mock_autocreate_user(false)
    User.expects(:find_by_sage_username).with('bob-the-new-user').returns(nil)
    User.expects(:build_with_sage_username).with({:username => 'bob-the-new-user'}).returns(new_user)
    @controller.expects(:auto_create_user?).returns(true)
    assert_equal new_user, 
      @controller.user_for_cas_user('bob-the-new-user', {}), 
      "user_for_cas_user should return existing user"
  end
  
  def test_user_id_for_cas_user
    username = mock('username')
    extra_attributes = mock('extra_attributes')
    user = mock('user') do
      expects(:id).returns(1234)
    end
    @controller.expects(:user_for_cas_user).with(username, extra_attributes).returns(user)
    assert_equal 1234,
      @controller.user_id_for_cas_user(username, extra_attributes)
  end
  
  def test_current_user_sets_current_user_on_api_token
    @controller.expects(:session).at_least_once.
      returns({
        :sage_user => 'castest_billingboss', 
        :cas_extra_attributes => {}
      })
    
    @controller.expects(:api_token?).returns(true)
    api_token = ApiToken.new
    @controller.expects(:api_token).returns(api_token)
    assert_equal users(:castest_billingboss),
      @controller.current_user,
      "current_user should have found user"
    assert_equal users(:castest_billingboss),
      api_token.user,
      "current_user should have set api_token user"
  end
  
  def test_current_user_returns_false_when_session_sage_user_empty
    @controller.expects(:session).at_least_once.returns({})
    assert_equal :false,
      @controller.current_user,
      "current_user should have returned :false when session has no sage_user"
  end
  
  def test_current_user_returns_existing_user_matching_session_sage_user
    @controller.expects(:session).at_least_once.
      returns({
        :sage_user => 'castest_billingboss', 
        :cas_extra_attributes => {}
      })
    assert_equal users(:castest_billingboss),
      @controller.current_user,
      "current_user should have returned existing user matching session sage_user"
  end
  
  def test_current_user_returns_new_user_matching_session_sage_user_when_autocreate_is_true
    user = mock_autocreate_user(false, 'nonexistant_user')
    User.expects(:build_with_sage_username).with({:username => 'nonexistant_user'}).returns(user)

    @controller.expects(:auto_create_user?).at_least_once.returns(true)
    @controller.expects(:session).at_least_once.
      returns({
        :sage_user => 'nonexistant_user',
        :cas_extra_attributes => {}
      })

    assert_equal user,
      @controller.current_user,
      "current_user should have returned new_user when autocreate is true"
  end
  
  def test_current_user_returns_false_when_autocreate_is_false
    @controller.expects(:auto_create_user?).at_least_once.returns(false)
    @controller.expects(:session).at_least_once.
      returns({
        :sage_user => 'nonexistant_user',
        :cas_extra_attributes => {}
      })

    assert_equal :false,
      @controller.current_user,
      "current_user should have returned :false when autocreate is false"
  end
  
  def test_login_with_email_resets_session_sage_user_to_username
    session_hash = {
      :sage_user => 'castest_billingboss@billingboss.com',
      :cas_extra_attributes => {
        :username => 'castest_billingboss'
      }
    }
    
    @controller.expects(:session).at_least_once.returns(session_hash)

    assert_equal users(:castest_billingboss),
      @controller.current_user,
      "current_user should have found user"

    assert_equal 'castest_billingboss',
      session_hash[:sage_user],
      "accssing current_user should have set session[:sage_user] to sage_username"

  end
  
  protected
  def stub_current_user_with_bob
    @controller.expects(:current_user).at_least_once.returns(mock_user)
  end
  
  def stub_session_with_bob
    @controller.expects(:session).at_least_once.returns(mock_session)
  end
  
  def stub_api_token
    @controller.stubs(:api_token).returns(mock_api_token)
    @controller.expects(:api_token?).at_least_once.returns(mock_api_token)
  end
  
  def mock_user
    if @mock_user.nil?
      @mock_user = mock('bob') do
        responds_like(User.new)
        stubs(:sage_username).returns('bob-the-user')
        stubs(:is_a?).with(User).returns(true)
      end
    end
    @mock_user
  end

  def mock_autocreate_user(credit_referral, sage_username='bob-the-user')
    user = mock('user') do
      responds_like(User.new)
      expects(:new_user).at_least_once.returns(true)
      expects(:set_signup_type)
      expects(:set_heard_from)
      expects(:credit_referral) if credit_referral
      expects(:save!).returns true
      stubs(:sage_username).returns(sage_username)
      stubs(:id).returns(1234)
    end
    user
  end
  
  def mock_existing_user
    user = mock('user') do
      responds_like(User.new)
    end
    user
  end
  
  def mock_session
    {:sage_user => 'bob-the-user'}
  end
  
  def mock_api_token
    api_token = mock("api_token") do
      responds_like(ApiToken.new)
      stubs(:service_url_prefix).returns("/api/mary")
    end
  end
end