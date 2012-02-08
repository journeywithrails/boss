$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class Sequence5BbUserGoesToSsTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.billingboss.ensure
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    SSO::SAM.prepare
    SSO::SBB.prepare(true)
    @user = watir_session.with_sage_user(:castest_billingboss)
    assert_recaptcha_off(@user)
    @user.logs_out_cas
    @debug = false
  end
 
  def test_happy_path
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working

    # start off logged in to billingboss
    assert_click_goto_bb_and_click_login(@user, @debug)
    assert_cas_login(@user, @debug)
    assert_logged_in_on_bb(@user,@debug)

    # then go to sagespark
    exit unless $test_ui.agree('go to sagespark...', true) if @debug  
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/mysage"
    assert_logged_in_on_sbb(@user,@debug)
    assert_on_ss_for_bb_users_landing_page(@user, @debug)
    
    # for now, the message will be gone if logout, log back in
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    assert_click_goto_sbb_and_click_login(@user, @debug)
    assert_cas_login(@user, @debug)    
    #Note: existing user will see a successful login message
    assert_logged_in_on_sbb(@user,@debug)
    deny_on_ss_for_bb_users_landing_page(@user, @debug)

    
  end
    
  def assert_on_ss_for_bb_users_landing_page(user, debug=false)
    exit unless $test_ui.agree('about to assert on special bb landing page. continue?', true) if debug  
    assert_match Regexp.new(SSO::SBB.special_landing_page), @user.url
  end

  def deny_on_ss_for_bb_users_landing_page(user,debug=false)
    exit unless $test_ui.agree('about to deny on special bb landing page. continue?', true) if debug  
    deny_match Regexp.new(SSO::SBB.special_landing_page), @user.url
  end
end