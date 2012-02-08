$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class SequenceNewUserGoesToBbTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.billingboss.ensure
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    SSO::SAM.prepare
    SSO::SBB.prepare(true)
    @user = watir_session
    assert_recaptcha_off(@user)
    @user.logs_out_cas
    @user.goto Sage::Test::Server.billingboss.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    @debug = false
  end
 
  def test_happy_path
    @user.with_sage_user(random_new_sage_user)
    @user.goto Sage::Test::Server.billingboss.url
    $test_ui.agree('home page. continue?', true) if @debug
    assert(@user.link(:text, /log ?in/i).exists?)   
    assert(@user.link(:text, /sign ?up/i).exists?)
    deny_logged_in_on_bb(@user, @debug)

    
    @user.goto Sage::Test::Server.billingboss.url
    @user.link(:text, /sign ?up/i).click
    
    exit unless $test_ui.agree('clicked signup. continue?', true) if @debug

    assert_on_bb_signup_page(@user)
    assert_match /profiles\/newedit/, extract_service_param_from_url(@user, @debug)
    user_fills_in_sam_signup_form(@user)

    
    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug

    #Note: existing user will see a successful login message
    assert_logged_in_on_bb(@user, @debug)
  end
end