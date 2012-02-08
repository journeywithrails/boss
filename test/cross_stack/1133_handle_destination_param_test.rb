$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

# http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1133

class HandleDestinationParamTest < Test::Unit::TestCase
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

  def test_signup_from_blog
    @user.with_sage_user(random_new_sage_user)
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/forum/welcome-sage-spark"
    exit unless $test_ui.agree('message. continue?', true) if @debug
    assert @user.contains_text(" Welcome to Sage Spark")
    
    assert @user.link(:id, 'signup-to-comment-link').exists?
    # exit unless $test_ui.agree('click register link?', true) if @debug
    @user.link(:id, 'signup-to-comment-link').click
    
    assert_on_profile_choice(@user)

    # @debug=true
    exit unless $test_ui.agree('clicked business profile. continue?', true) if @debug
    click_choose_profile_link(@user, 'business')

    assert_on_sam_signup_page(@user)

    user_fills_in_sam_signup_form(@user)

    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug

    @user.link(:id, "TB_closeWindowButton").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug
    assert @user.contains_text("Welcome, #{@user.user.username.capitalize}")
    assert @user.contains_text("Welcome to Sage Spark")
    assert @user.contains_text("Reply")
    assert @user.contains_text("Comment:")
    assert @user.contains_text("Your name:")
    assert @user.button(:value, /post comment/i).exists?
  end

  def test_login_from_blog
    @user.with_sage_user(:castest)
    # @debug=true
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/forum/welcome-sage-spark"
    exit unless $test_ui.agree('message. continue?', true) if @debug
    assert @user.contains_text(" Welcome to Sage Spark")
    
    assert @user.link(:id, 'login-to-comment-link').exists?
    exit unless $test_ui.agree('click login link?', true) if @debug
    @user.link(:id, 'login-to-comment-link').click
    # @debug=true
    assert_cas_login(@user, @debug)
    exit unless $test_ui.agree('about to assert welcome. continue?', true) if @debug
    assert @user.contains_text("Welcome, #{@user.user.username.capitalize}")
    assert @user.contains_text(" Welcome to Sage Spark")
    assert @user.contains_text("Reply")
    assert @user.contains_text("Comment:")
    assert @user.contains_text("Your name:")
    assert @user.button(:value, /post comment/i).exists?
    exit unless $test_ui.agree('done?', true) if @debug
  end
end