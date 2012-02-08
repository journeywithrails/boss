$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

# http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1133

class DefaultSignupGoesToSbbTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user = watir_session
    SSO::SAM.prepare
    SSO::SBB.prepare
    @user.logs_out_cas
    assert_recaptcha_off(@user)
    @debug=false
  end

  def test_signup_from_default
    @user.with_sage_user(random_new_sage_user)
    @user.goto Sage::Test::Server.sageaccountmanager.url

    assert_on_sam_signup_page(@user, @debug)

    user_fills_in_sam_signup_form(@user)

    exit unless $test_ui.agree('click register?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug

    assert_on_profile_choice(@user)

    exit unless $test_ui.agree('before clicking business profile. continue?', true) if @debug
    # debugger if @debug
    click_choose_profile_link(@user, 'business')

    assert_on_congratulations_popup(@user, @debug)
    @user.link(:id, "TB_closeWindowButton").click
    
    assert_on_my_sage_on_sbb(@user, :business, @debug)
    exit unless $test_ui.agree('chose business profile. continue?', true) if @debug
  end


end