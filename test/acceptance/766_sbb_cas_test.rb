$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/../cas_acceptance_helper'

# Test cases for User Story 814

###########   Notes #################

# 1. Assumes the cas server is running at CasServerHelper.cas_login_url (https://castest.billingboss.com). The billing boss certificate should be installed and unlocked and named castest.billingboss.com, and an entry in the hosts file pointing castest.billingboss.com to localhost.
# 
# 2. Assumes the test cas server is configured to use the sage_users table in the test database. This will get all the cas users via the sage_users fixture
# 
# 


class SbbCasTest < Test::Unit::TestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    
    @user = watir_session.with(:user_without_profile)
    @user.logs_out_cas # need this in case other tests haven't cleaned up
    @user.ensure_sbb_logged_out
    #@user.logs_out # need this in case other tests haven't cleaned up
  end
  
  def teardown
    @user.teardown
    $log_on = false
  end

  
  def test_sbb_success_login_logout
    # $debug = true
    
    @user.goto_sbb_login_url
    
    
    
    assert @user.text_field(:id,"username").exists?
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page when clicking login. Actual URL is " + @user.url    
    

    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    @user.button(:name, "login-btn").click

    #Note: new user will see the create new profile page.
    assert_match sbb_create_profile_url, @user.url(), "Does not see create profile page after logging in without profile. Actual URL is " + @user.url
    #Other users will see their created profile page.
    #assert_match sbb_users_url + "/users/" + @user.user.sage_username, @user.url(), "Does not see logged in page after logging in. Actual URL is " + @user.url

    @user.goto_sbb_logout_url

    @user.goto_sbb_my_profile_url
    #should be redirect to the login page

    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page after logging out. Actual URL is " + @user.url    
    assert @user.button(:name, "login-btn").exists?
   end
   
  def test_sbb_login_with_bad_password
    @user.goto_sbb_login_url
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("testaa"))
    @user.button(:name, "login-btn").click
    
    #should be redirect to the login page
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page after incorrect password. Actual URL is " + @user.url    
    assert @user.button(:name, "login-btn").exists?
  end
  
  def test_sbb_login_with_bad_username
    @user.goto_sbb_login_url
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page when clicking login. Actual URL is " + @user.url    
    @user.populate(@user.text_field(:id,"username"),("nosuchuser@nowhere.com"))
    @user.populate(@user.text_field(:id,"password"),("test"))
    @user.button(:name, "login-btn").click
    #should be redirect to the login page
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page after incorrect username. Actual URL is " + @user.url    
    assert @user.button(:name, "login-btn").exists?
  end

  def test_sbb_use_cas_server_to_login_as_different_user
    flunk "not implemented yet"
  end

  private
end