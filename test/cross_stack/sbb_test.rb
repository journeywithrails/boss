$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class SbbTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    @user = watir_session.with_sage_user(:castest)
    SSO::SAM.prepare
    assert_recaptcha_off(@user)
    SSO::SBB.prepare(true)
    @user.logs_out_cas
    @debug = false
  end

  def test_site_comes_up
    # @debug=true
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    assert(@user.link(:text, "Login").exists?)   
    $test_ui.agree('home page. continue?', true) if @debug
    
    # assert that the sagespark logo is in page
    $test_ui.agree('continue?', true) if @debug
    # assert @user.image(:id, "sagespark-logo").exists?, "could not find the sagespark logo on page"
  end
    
  # this will test logging in with a user that exists in SAM but not in SBB (because setup calls SSO::SBB.prepare(true)
  #  which clears out all castest users from sbb db). then it will logout & log back in again.
  def test_login_logout_with_no_profile_source_bb
    @user = watir_session.with_sage_user(:castest_billingboss)    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    # @debug=true

    assert_click_goto_sbb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)
    
    #Note: existing user will see a successful login message
    assert_logged_in_on_sbb(@user)

    exit unless $test_ui.agree('logged in. continue?', true) if @debug
    
    # because the source of this user is billingboss, we will be on the special billingboss landing page
    assert_match Sage::Test::Server.sagebusinessbuilder.url + SSO::SBB.special_landing_page, @user.url(), "should see create profile page after logging in without profile. Actual URL is " + @user.url

    assert_user_can_logout_from_sbb(@user)

  end
  
  # this will test logging in with a user that exists in SAM but not in SBB (because setup calls SSO::SBB.prepare(true)
  #  which clears out all castest users from sbb db). then it will logout & log back in again.
  def test_login_logout_with_no_profile_source_bb
    @user = watir_session.with_sage_user(:castest_sbb_incomplete)    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    # @debug=true

    assert_click_goto_sbb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)
    
    #Note: existing user will see a successful login message
    assert_logged_in_on_sbb(@user)

    exit unless $test_ui.agree('logged in. continue?', true) if @debug
    
    assert_match Sage::Test::Server.sagebusinessbuilder.url + '/signup/profile', @user.url(), "should see create profile page after logging in without profile. Actual URL is " + @user.url
    deny_match Sage::Test::Server.sagebusinessbuilder.url + SSO::SBB.special_landing_page, @user.url(), "should see create profile page after logging in without profile. Actual URL is " + @user.url

    assert_user_can_logout_from_sbb(@user)

  end
  
  #  test login with pre-existing user with business profile set
  def test_login_logout_with_business_profile
    @user.with_sage_user(:castest_with_business_profile)
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working

    assert_click_goto_sbb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)
    
    #Note: existing user will see a successful login message
    # @debug=true
    assert_logged_in_on_sbb(@user, @debug)

    
    deny_match Sage::Test::Server.sagebusinessbuilder.url + "/signup/profile", @user.url(), "should see create profile page after logging in without profile. Actual URL is " + @user.url
    
    assert_on_my_sage_on_sbb(@user, :business, @debug)

    exit unless $test_ui.agree('logged in. continue?', true) if @debug

    assert_user_can_logout_from_sbb(@user)

  end
  
  #  test login with pre-existing user with personal profile set
  def test_login_logout_with_personal_profile
    @user.with_sage_user(:castest_with_personal_profile)
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working

    assert_click_goto_sbb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)
    
    #Note: existing user will see a successful login message
    # @debug=true
    assert_logged_in_on_sbb(@user, @debug)

    
    deny_match Sage::Test::Server.sagebusinessbuilder.url + "/signup/profile", @user.url(), "should see create profile page after logging in without profile. Actual URL is " + @user.url

    assert_on_my_sage_on_sbb(@user, :personal, @debug)

    exit unless $test_ui.agree('logged in. continue?', true) if @debug

    assert_user_can_logout_from_sbb(@user)

  end
  
  
  # tests that single signout is working on sbb
  def test_login_sbb_logout_elsewhere
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    $test_ui.agree('start. continue?', true) if @debug
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    $test_ui.agree('home page. continue?', true) if @debug

    assert_click_goto_sbb_and_click_login(@user, @debug)

    assert_cas_login(@user, @debug)

    # @debug = true
    $test_ui.agree('clicked login on cas. continue?', true) if @debug

    #Note: existing user will see a successful login message
    assert_logged_in_on_sbb(@user)
    #should be redirect to the login page

    assert_logout_elsewhere_logsout_sbb(@user, @debug)
  end

  # refs #1862
  def test_login_bb_goto_sbb_logout_elsewhere
    # login on BB
    @user.goto Sage::Test::Server.billingboss.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    assert_click_goto_bb_and_click_login(@user, @debug)
    assert_cas_login(@user, @debug)
    assert_logged_in_on_bb(@user,@debug)

    # goto sbb
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/mysage'
    $test_ui.agree('mysage. continue?', true) if @debug
    assert_logged_in_on_sbb(@user)

    #  go back to bb & logout
    @user.goto Sage::Test::Server.billingboss.url
    assert_user_can_logout_from_bb(@user)
    
    # go back to sbb & ensure logged out
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    deny @user.link(:id, "logout-link").exists?, "should not be a logout link on the page"
    deny @user.contains_text(@user.user.username.capitalize)
    assert @user.link(:id, "login-link").exists?
    assert_no_warning(@user, @debug)
    
    $test_ui.agree('goto mysage. continue?', true) if @debug
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/mysage'
    $test_ui.agree('mysage. continue?', true) if @debug
    assert_cas_login(@user, @debug)
    
  end
  
  def test_signup
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    @user.with_sage_user(random_new_sage_user)
    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    assert @user.link(:id, "signup-link").exists?
    # exit unless $test_ui.agree('click signup?', true) if @debug
    @user.link(:id, "signup-link").click
    
    # @debug = true
    exit unless $test_ui.agree('clicked signup. continue?', true) if @debug

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

    #Note: existing user will see a successful login message
    # @debug = true
    assert_logged_in_on_sbb(@user, @debug)

    # @debug=true 
    assert_logout_elsewhere_logsout_sbb(@user, @debug)

  end
  
  # http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1118
  # def xxx_test_reload_until_spurious_logout
  #   @debug=true
  #   @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # temporary until logout issue fixed
  # 
  #   assert_click_goto_sbb_and_click_login(@user, @debug)
  # 
  #   assert_cas_login(@user, @debug)
  # 
  #   $test_ui.agree('logged in. continue?', true) if @debug
  #   assert_logged_in_on_sbb(user)
  #   time = 0
  #   loop do
  #     60.times do
  #       time += 10
  #       sleep 10
  #       puts "#{time}..."
  #     end
  #     puts
  #     File.open('/var/log/drupal/watir.log', 'a') {|f| f.write("\n\n\n#{Time.now} -------  checking for spurious logout #{time} seconds") }
  #     puts "#{Time.now} -------  checking for spurious logout #{time} seconds"
  #     @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/tools_services/home"
  #     unless @user.contains_text("Welcome, Castest")
  #       File.open('/var/log/drupal/watir.log', 'a') {|f| f.write("\n\n\n#{Time.now} ! ! ! ! ! ! found spurious logout") }
  #       $test_ui.agree('found spurious logout. continue?', true)
  #     end
  #     @user.goto Sage::Test::Server.sagebusinessbuilder.url
  #     unless @user.contains_text("Welcome, Castest")
  #       File.open('/var/log/drupal/watir.log', 'a') {|f| f.write("\n\n\n#{Time.now} ! ! ! ! ! ! found spurious logout") }
  #       $test_ui.agree('found spurious logout. continue?', true)
  #     end
  #   end    
  # end
end