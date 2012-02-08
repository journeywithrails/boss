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


class CasTest < Test::Unit::TestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    # @debug = true
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.cas_server_sage.ensure
    
    @user = watir_session.with(:user_without_profile)
    @user.logs_out_cas # need this in case other tests haven't cleaned up
  end
  
  def teardown
    @user.teardown
    $log_on = false
  end

  
  def test_success_login_logoff
    @user.goto_login_url
    
    assert @user.text_field(:id,"username").exists?
    assert_match(/#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page when clicking login. Actual URL is " + @user.url)    
    
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    $test_ui.agree('continue?', true) if @debug
    
    @user.button(:name, "login-btn").click
    
    $test_ui.agree('continue?', true) if @debug

    assert_equal "Profiles: edit", @user.title 
    @user.assert_user_owns_page(:user_without_profile)

    @user.goto_logoff_url
    @user.assert_home

    @user.goto_new_invoice_site_url
    #should be redirect to the login page

    assert_match(/#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page after logging out. Actual URL is " + @user.url)    
    assert @user.button(:name, "login-btn").exists?
  end
   
  def test_login_with_bad_password
    @user.goto_login_url
    $test_ui.agree('continue?', true) if @debug
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("testaa"))
    @user.button(:name, "login-btn").click
    
    #should be redirect to the login page
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page after incorrect password. Actual URL is " + @user.url    
    assert @user.button(:name, "login-btn").exists?
  end
  
  def test_login_with_bad_username
    @user.goto_login_url    
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page when clicking login. Actual URL is " + @user.url    
    @user.populate(@user.text_field(:id,"username"),("nosuchuser@nowhere.com"))
    @user.populate(@user.text_field(:id,"password"),("test"))
    @user.button(:name, "login-btn").click
    #should be redirect to the login page
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page after incorrect username. Actual URL is " + @user.url    
    assert @user.button(:name, "login-btn").exists?
  end

  def off_test_use_cas_server_to_login_as_different_user
    # currently there is no logout button on the cas login confirmation page, so can't sign in as different user without logging out
    @user.goto_login_url
    
    assert @user.text_field(:id,"username").exists?
    assert_match /#{::CasServerHelper.cas_login_url}/, @user.url(), "Does not see the login page when clicking login. Actual URL is " + @user.url    
    
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    
    @user.button(:name, "login-btn").click
    

    assert_equal "Profiles: edit", @user.title 
    @user.assert_user_owns_page(:user_without_profile)
    
    @user.goto_cas_login_url
    assert @user.text_field(:id,"username").exists?, "should be on logon page but found: \n#{@user.html}"
    @user.populate(@user.text_field(:id,"username"),(users(:basic_user).sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    @user.button(:name, "login-btn").click
    
    @user.goto_profile_url
    assert_equal "Profiles: edit", @user.title 
    @user.assert_user_owns_page(:basic_user)
    
  end

  def test_logout_does_nothing_evil_if_user_not_logged_in
  end
  
  def test_login_works_correctly_if_user_already_logged_in
  end
  
  def test_signup_via_sam_auto_logs_in_and_creates_user
    new_user_login = 'new_cas_user_for_test'
    @user.destroy_sage_user(new_user_login) # in case previous test did not cleanup
    @user.goto_home_url
    @user.assert_home
    # exit unless $test_ui.agree('continue?', true) if @debug
    
    assert @user.link(:id, 'signup-link').exists?
    @user.link(:id, 'signup-link').click

    new_user_email = "new_cas_user_for_test@billingboss.com"
    @user.populate(@user.text_field(:id,"sage_user_username"),(new_user_login))
    @user.populate(@user.text_field(:id,"sage_user_email"),(new_user_email))
    @user.populate(@user.text_field(:id,"sage_user_password"),("test"))
    @user.populate(@user.text_field(:id,"sage_user_password_confirmation"),("test"))
    @user.checkbox(:id, "sage_user_terms_of_service").set
    @user.button(:id, "register_button").click
    
    # exit unless $test_ui.agree('continue?', true) if @debug
    assert @user.contains_text("Logged in as #{new_user_login}"), "did not see logged in text"
    @user.goto_profile_url
    assert_equal "Profiles: edit", @user.title 
    @user.assert_user_owns_page(new_user_login)
    
    new_user = User.find_by_sage_username(new_user_login)
    assert_not_nil(new_user)
    assert_equal(new_user_email, new_user.email)
    
    @user.destroy_sage_user(new_user_login)
  end
  
  def test_cas_login_stores_ticket_user_association
    CasServiceTicket.delete_all
    @user.goto_login_url
    # exit unless $test_ui.agree('continue?', true) if @debug
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    assert_difference('CasServiceTicket.count', 1) do
      @user.button(:name, "login-btn").click
    end

    @user.assert_user_owns_page(@user.user.sage_username)
    # exit unless $test_ui.agree('continue?', true) if @debug
    cas_service_ticket = CasServiceTicket.find(:first)
    assert_equal cas_service_ticket.user_id, @user.user.id
    
    current_session = @user.current_session(:sage_user, :cas_last_valid_ticket)
    assert_equal "user_without_profile", current_session[:sage_user]
    assert_equal cas_service_ticket.st_id, current_session[:cas_last_valid_ticket].ticket
    # puts "current_session: #{current_session.inspect}"
  end
  
  def test_cas_logout_destroys_user_tickets_and_subsequent_filter_redirects

    # login to BB
    
    @user.goto_login_url
    exit unless $test_ui.agree('continue?', true) if @debug
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    assert_difference('CasServiceTicket.count', 1) do
      @user.button(:name, "login-btn").click
    end
    @user.assert_user_owns_page(@user.user.sage_username)
    current_session = @user.current_session(:sage_user, :cas_last_valid_ticket)
    current_ticket = current_session[:cas_last_valid_ticket].ticket
    assert_equal "user_without_profile", current_session[:sage_user]

    # hit another page. should reuse last ticket
    
    assert_no_difference('CasServiceTicket.count') do
      @user.goto_invoices_url
      @user.assert_on_page '/invoices', "hitting invoices page after logging in failed"
      @user.assert_user_owns_page(@user.user.sage_username)
    end
    
    current_session = @user.current_session(:sage_user, :cas_last_valid_ticket)
    assert_equal current_ticket, current_session[:cas_last_valid_ticket].ticket, "while logged in did not reuse last ticket"
   
    assert_difference('CasServiceTicket.count', -1, "logging out on cas should have deleted CasServiceTicket") do
      exit unless $test_ui.agree('continue?', true) if @debug
      @user.goto_cas_logout_url
      @user.assert_on_cas_page('logout', "expected to be on cas logout page but wasn't")
      assert @user.contains_text("Logout successful"), "did not see 'Logout successful' on logout page"
    end

    
    @user.goto_home_url
    deny @user.contains_text("Logged in as"), "billingboss was still logged in "
    
    @user.goto_invoices_url
    @user.assert_on_cas_page('login', "expected to be on cas login page but wasn't")
    
    # make sure nothing is broken with logging in again after being logged out
    @user.populate(@user.text_field(:id,"username"),(@user.user.sage_username))
    @user.populate(@user.text_field(:id,"password"),("test"))
    assert_difference('CasServiceTicket.count', 1) do
      @user.button(:name, "login-btn").click
    end
    @user.assert_user_owns_page(@user.user.sage_username)
    
  end
  
  def test_cas_logged_in_on_two_browsers_logout_logs_out_both
  end
  
  def test_cas_logout_logs_out_bb_and_sbb
  end
  
  private
end