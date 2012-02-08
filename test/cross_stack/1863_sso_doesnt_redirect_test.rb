$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class SsoDoesntRedirectTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.billingboss.ensure
    # @user = watir_session.with_sage_user(:castest_with_personal_profile) # must use a sage_user for which there is no bb user yet
    @user = watir_session.with_sage_user(:castest)
    SSO::SAM.prepare
    assert_recaptcha_off(@user)
    # SSO::BB.prepare(true)
    @user.logs_out_cas
    @debug = false
  end

  def test_sso_not_clearing_links
    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    
    # create a fresh sbb user. This could be moved to a fixture, as it is tested elsewhere
    @user.with_sage_user(valid_sage_user(random_name_and_address))    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    assert @user.link(:id, "signup-link").exists?
    @user.link(:id, "signup-link").click
    assert @user.contains_text("Sign up")
    assert @user.contains_text(/business profile/i)
    assert @user.contains_text(/personal profile/i)
    @user.link(:href, /signup.*business/i).click
    assert_on_sam_signup_page(@user)
    user_fills_in_sam_signup_form(@user)
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug
    assert_logged_in_on_sbb(@user, @debug)
    
    @user.goto Sage::Test::Server.billingboss.url
    
    assert_bb_login_link_points_to_sagespark(@user)

    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working 

    assert_click_goto_bb_and_click_login(@user)  
    assert_cas_login(@user, @debug)  

  end
  
end