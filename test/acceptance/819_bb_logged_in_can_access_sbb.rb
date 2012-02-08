$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/../cas_acceptance_helper'

# Test cases for CAS User Story 5, ticket 819

###########   Notes #################

# 1. Assumes the cas server is running at CasServerHelper.cas_login_url (https://castest.billingboss.com). The billing boss certificate should be installed and unlocked and named castest.billingboss.com, and an entry in the hosts file pointing castest.billingboss.com to localhost.
# 
# 2. Assumes the test cas server is configured to use the sage_users table in the test database. This will get all the cas users via the sage_users fixture
# 
# 

class SbbAndBbCasTest2 < Test::Unit::TestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    ensure_cas_server
    ensure_sbb_server
    @user = watir_session.with(:user_without_profile)
    @user.ensure_sbb_logged_out
    @user.logs_out # need this for bb in case other tests haven't cleaned up
  end
  
  def teardown
    @user.teardown
    $log_on = false #bb
  end

  
  def test_sbb_success_login_logout

    @user.goto_cas_login_url
    
    assert @user.text_field(:id,"username").exists?
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page when clicking login. Actual URL is " + @user.url    
    
    @user.populate(@user.text_field(:id,"username"),@user.user.sage_username)
    @user.populate(@user.text_field(:id,"password"),"test")
    @user.button(:name, "submit").click
    

    assert_equal "Profiles: edit", @user.title 

    #switch to sage business builder when already logged in.
    @user.goto_sbb_login_url
    #Note: new user will see the create new profile page.
    assert_match sbb_create_profile_url, @user.url(), "Does not see create profile page after logging in without profile. Actual URL is " + @user.url
    #Other users will see their created profile page.
    #assert_match sbb_users_url + "/users/" + @user.user.sage_username, @user.url(), "Does not see logged in page after logging in. Actual URL is " + @user.url

    @user.goto_sbb_logout_url
    @user.wait()
    
   end
   
  private
end
