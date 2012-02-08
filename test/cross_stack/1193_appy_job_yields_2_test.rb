$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

# http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1133

class ApplyJobYields2 < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user = watir_session.with_sage_user(:castest_with_personal_profile)
    SSO::SAM.prepare
    SSO::SBB.prepare(true)
    @user.logs_out_cas
    assert_recaptcha_off(@user)
    @debug = false
  end

  def test_apply_job_when_not_logged_in

    # first time through, user does not exist
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/find/job"
    assert @user.contains_text("Find a Job")
    
    # @debug = true
    exit unless $test_ui.agree('clicked apply_job. continue?', true) if @debug
    apply_job_link_expr = /[\/=]apply_job\//
    assert @user.link(:href, apply_job_link_expr).exists?
    @user.link(:href, apply_job_link_expr).click

    exit unless $test_ui.agree('clicked apply_job. continue?', true) if @debug
    assert_cas_login(@user, @debug, false)


    exit unless $test_ui.agree('done no pre-existing user?', true) if @debug
    assert @user.contains_text("Application For")
    assert @user.button(:value, "Submit Application").exists


    assert @user.contains_text("Find a Job")
    assert_user_can_logout_from_sbb(@user, @debug, false)
    
    exit unless $test_ui.agree('try again now that user exists?', true) if @debug

    # now retry with user existing
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/find/job"
    assert @user.contains_text("Find a Job")
    
    assert @user.link(:href, apply_job_link_expr).exists?
    @user.link(:href, apply_job_link_expr).click

    assert_cas_login(@user, @debug, false)

    exit unless $test_ui.agree('done?', true) if @debug
    assert @user.contains_text("Application For")
    assert @user.button(:value, "Submit Application").exists
    
  end

  def xxxt_test_apply_job_when_logged_in
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/forum/welcome-sage-spark"
    assert @user.contains_text("Welcome to Sage Spark")
    
    assert @user.link(:id, 'login-to-comment-link').exists?
    exit unless $test_ui.agree('click login link?', true) if @debug
    @user.link(:id, 'login-to-comment-link').click

    assert_cas_login(@user, @debug)

    assert @user.contains_text("Welcome, Castest")
    exit unless $test_ui.agree('logged in. continue?', true) if @debug
    assert @user.contains_text("Reply")
    assert @user.button(:value, /post comment/i).exists?
    
    
    exit unless $test_ui.agree('done?', true) if @debug
  end
end