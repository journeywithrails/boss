$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class SequenceNewUserGoesToSsTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.billingboss.ensure
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    @user = watir_session
    assert_recaptcha_off(@user)
    SSO::SAM.prepare
    SSO::SBB.prepare(true)
    SSO::Proveng.prepare(true)
    @user.logs_out_cas
    @debug = false    
  end
 
  def test_new_user_goes_to_sagespark_to_signup_for_billingboss
    # @debug=true
    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    @user.with_sage_user(valid_sage_user(random_name_and_address))    
    deny User.exists?(:sage_username => @user.username), "user should not have a billingboss user account"

    # go to sagespark as a new user (not logged in)
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    assert @user.link(:id, "signup-link").exists?
    deny_logged_in_on_sbb(@user, @debug)

    # go to the free tools page
    @user.link(:text, /tools \& services/i).fire_event("onmouseover")
    @user.link(:text, /free tools/i).click    
    assert_on_free_tools_page(@user, @debug)
    
    # click billing boss link
    @user.link(:text, /billing boss/i).click    
  
    # click sign up link for billing boss, and get asked to authenticate
    @user.button(:value, /sign ?up now/i).click
    assert @user.contains_text("My Subscription Cart")
    assert @user.button(:id, "checkout-button").exists?
    @user.button(:id, "checkout-button").click
    
    exit unless $test_ui.agree('clicked sign up. on authentication page?', true) if @debug
    assert_on_sage_spark_authentication_page(@user, @debug)

    assert @user.contains_text("Login")
    @user.link(:text, /create account/i).click    
    
    assert @user.contains_text("Sign up")
    assert @user.contains_text(/business profile/i)
    assert @user.contains_text(/personal profile/i)

    @user.link(:href, /signup.*business/i).click
    exit unless $test_ui.agree('clicked business profile. continue?', true) if @debug

    assert_on_sam_signup_page(@user)

    user_fills_in_sam_signup_form(@user)
    
    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug    
 
    assert_on_billing_info_page(@user, @debug) 
    
    user_fills_in_billing_info_form(@user)
    
    # click next button
    @user.button(:value, /next/i).click  

    @debug=true
    assert_on_free_tool_summary_page(@user, @debug)    
    
    # click start using service now
    @user.link(:text, /Start using your services now/).click    

    assert_on_my_tools_and_services_page(@user, @debug)    

    # wait until access button exists
    Watir::Waiter.new(60).wait_until do
      if @user.contains_text("Access")
        true
      else
        sleep(5)
        @user.link(:text, /refresh/i).click         
        false
      end
    end

    @user.goto Sage::Test::Server.billingboss.url
    assert_logged_in_on_bb(@user, @debug)
    
  end
end