$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

class HandleCasErrorDuringSignup < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    @user = watir_session
    Sage::Test::Server.cas_server_sage.kill
    Sage::Test::Server.sageaccountmanager.ensure
    SSO::SAM.prepare
    assert_recaptcha_off(@user)
    @debug = false
  end

  def teardown
    Sage::Test::Server.cas_server_sage.ensure
  end
  
  def test_autologin_fails_gracefully
    @debug = true
    @user.with_sage_user(random_new_sage_user)    
    @user.goto Sage::Test::Server.billingboss.url
    exit unless $test_ui.agree('on billingboss?', true) if @debug
    @user.link(:text, /sign ?up/i).click
    
    exit unless $test_ui.agree('clicked signup. continue?', true) if @debug

    user_fills_in_sam_signup_form(@user)
    
    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug


  end
  
end