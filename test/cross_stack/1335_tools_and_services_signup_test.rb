$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

# http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1133

class ToolsAndServicesSignupTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    @user = watir_session
    SSO::SAM.prepare
    SSO::SBB.prepare
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user.logs_out_cas
    assert_recaptcha_off(@user)
    @debug=false
  end

  def test_buy_virtual_helpdesk_creating_account
    @user.with_sage_user(random_new_sage_user)
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/tools_services/it_services/it_services/live_computer_support"
    exit unless $test_ui.agree('on virtual helpdesk?. continue?', true) if @debug
    @user.button(:name, "btnOrderNow").click
    assert @user.contains_text("Add to Cart")
    @user.button(:value, "Add to Cart").click
    assert @user.contains_text("My Subscription Cart")
    exit unless $test_ui.agree('click Checkout?. continue?', true) if @debug
    @user.button(:id, "checkout-button").click
    assert_on_cas_login_page(@user, @debug)
    exit unless $test_ui.agree('click create account on cas?', true) if @debug

    @user.div(:id, "create-account-link").link(:text, "Create Account").click

    exit unless $test_ui.agree('clicked create account. continue?', true) if @debug    
    assert_on_profile_choice(@user)

    click_choose_profile_link(@user, 'business')
    # exit unless $test_ui.agree('clicked business profile. continue?', true) if @debug

    assert_on_sam_signup_page(@user)

    user_fills_in_sam_signup_form(@user)

    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    
    # begin
    #   @user.link(:id, "TB_closeWindowButton").click
    # rescue
    # end
    

    exit unless $test_ui.agree('clicked register on sam. probably need to have provisioning engine setup/running for this to work. continue?', true) if @debug
    assert @user.contains_text("Welcome, #{@user.user.username.capitalize}")
    assert @user.contains_text("Enter Your Billing Address"), "should contain Enter Your BillingAddress"
  end

end