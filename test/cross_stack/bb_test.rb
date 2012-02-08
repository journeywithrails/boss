$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class BbTest < Test::Unit::TestCase
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

  def test_site_comes_up
    # @debug=true
    @user.goto Sage::Test::Server.billingboss.url
    $test_ui.agree('home page. continue?', true) if @debug
    assert(@user.link(:text, /log ?in/i).exists?)   
    assert(@user.link(:text, /sign ?up/i).exists?)   
    
    # assert that the sagespark logo is in page
    $test_ui.agree('continue?', true) if @debug
    assert @user.div(:id, "logo").exists?, "could not find the billingboss logo on page"
    assert @user.contains_text(/What is Billing Boss/i)
  end
    
  # this will test logging in with a user that exists in SAM but not in BB (because setup calls SSO::BB.prepare(true)
  #  which clears out all castest users from sbb db). then it will logout & log back in again.
  def test_login_logout
    @user.goto Sage::Test::Server.billingboss.url + '/caslogout' # ensure starting logged out even is single sign out isn't working

    exit unless $test_ui.agree('logged out. continue?', true) if @debug    
    assert_click_goto_bb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)
    
    #Note: existing user will see a successful login message
    assert_logged_in_on_bb(@user,@debug)

    exit unless $test_ui.agree('logged in. continue?', true) if @debug
    
    # assert_match Sage::Test::Server.billingboss.url + "/profiles/newedit", @user.url(), "should see create profile page after logging in without profile. Actual URL is " + @user.url
    assert_match Sage::Test::Server.billingboss.url + "/profiles", @user.url(), "should see create profile page after logging in. Actual URL is " + @user.url

    assert_user_can_logout_from_bb(@user)

  end
  

  
  # tests that single signout is working on bb
  def test_login_logout_elsewhere
    @user.goto Sage::Test::Server.billingboss.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    $test_ui.agree('start. continue?', true) if @debug
    @user.goto Sage::Test::Server.billingboss.url
    $test_ui.agree('home page. continue?', true) if @debug

    assert_click_goto_bb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)

    # @debug = true
    $test_ui.agree('clicked login on cas. continue?', true) if @debug

    #Note: existing user will see a successful login message
    assert_logged_in_on_bb(@user)

    # assert_match sbb_create_profile_url, @user.url(), "Does not see create profile page after logging in without profile. Actual URL is " + @user.url

    #Other users will see their created profile page.
    #assert_match sbb_users_url + "/users/" + @user.user.username, @user.url(), "Does not see logged in page after logging in. Actual URL is " + @user.url


    # @user.goto_sbb_my_profile_url
    #should be redirect to the login page

    assert_logout_elsewhere_logsout_bb(@user, @debug)
  end

  def test_signup
    @user.goto Sage::Test::Server.billingboss.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    @user.with_sage_user(random_new_sage_user)
    
    @user.goto Sage::Test::Server.billingboss.url
    assert @user.link(:text, /sign ?up/i).exists?
    # exit unless $test_ui.agree('click signup?', true) if @debug
    @user.link(:text, /sign ?up/i).click
    
    exit unless $test_ui.agree('clicked signup. continue?', true) if @debug

    #assert @user.contains_text("Sign up")
    assert_on_bb_signup_page(@user, @debug)

    user_fills_in_sam_signup_form(@user, nil, @debug)
    
    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug

    #Note: existing user will see a successful login message
    assert_logged_in_on_bb(@user, @debug)

    assert_logout_elsewhere_logsout_bb(@user, @debug)

  end
  
end