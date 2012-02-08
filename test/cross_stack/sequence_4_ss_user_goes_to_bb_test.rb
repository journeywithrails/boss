$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class Sequence4SsUserGoesToBbTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.billingboss.ensure
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    #@user = watir_session.with_sage_user(:castest)
    @user = watir_session
    SSO::SAM.prepare
    assert_recaptcha_off(@user)
    SSO::SBB.prepare(true)
    @user.logs_out_cas
    @debug = false
  end
  
  def test_ss_user_clicks_bb_signup
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    
    # create a fresh sbb user. This could be moved to a fixture, as it is tested elsewhere
    @user.with_sage_user(valid_sage_user(random_name_and_address))    
    @user.goto Sage::Test::Server.sagebusinessbuilder.url
    assert @user.link(:id, "signup-link").exists?
    @user.link(:id, "signup-link").click
    assert @user.contains_text("Sign up")
    assert @user.contains_text(/business profile/i)
    assert @user.contains_text(/personal profile/i)
    @user.link(:href, /signup.*business/i).click
    assert_on_sam_signup_page(@user)
    user_fills_in_sam_signup_form(@user)
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug
    assert_logged_in_on_sbb(@user, @debug)


    # go to billingboss with logged in sagespark user
    exit unless $test_ui.agree('go to billingboss with new user?', true) if @debug
    @user.goto Sage::Test::Server.billingboss.url
    deny_logged_in_on_bb(@user, @debug)
    deny User.exists?(:sage_username => @user.username), "sage spark user going to billingboss should not have a billingboss user account"
    # verify that the login & signup links point to sagespark
    exit unless $test_ui.agree('assert login & signup point to sagespark?', true) if @debug
    
    assert_bb_signup_link_points_to_sagespark(@user, @debug)
    assert_bb_login_link_points_to_sagespark(@user, @debug)
    # verify that a bb user was NOT auto-created
  
    # click billing boss login link, and verify it shows correct sagespark page
    @user.link(:text, /log ?in/i).click
    assert_on_sbb_bb_signup_page(@user, @debug)

    # click billing boss signup link, and verify it shows correct sagespark page
    @user.goto Sage::Test::Server.billingboss.url
    deny_logged_in_on_bb(@user, @debug)
    deny User.exists?(:sage_username => @user.username), "sage spark user going to billingboss should not have a billingboss user account"
    @user.link(:text, /sign ?up/i).click
    assert_on_sbb_bb_signup_page(@user, @debug)

    # click sign up link for billing boss
    @user.button(:value, /sign ?up now/i).click
    assert_on_billing_info_page(@user, @debug) 
    
    # enter billing information & submit
    user_fills_in_billing_info_form(@user)
    @user.button(:value, /next/i).click
    assert_on_free_tool_summary_page(@user, @debug)    
    
    # click start using service now
    @user.link(:text, /start using your services now/i).click    

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

    assert User.exists?(:sage_username => @user.username), "billingboss account should exist after provisioning complete"
    #@debug = true
    @user.goto Sage::Test::Server.billingboss.url
    assert_logged_in_on_bb(@user, @debug)

  end  
 
  def test_ss_user_provisions_bb
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/caslogout' # ensure starting logged out even is single sign out isn't working

    @user.with_sage_user(valid_sage_user(random_name_and_address))
    
    puts "doing it with #{@user.username}"
    `echo "\n\n\n\n\n\n\n\n #{Time.now} test_ss_user_provisions_bb #{@user.username}\n\n\n\n\n" | cat >> /Users/lasto/clients/sage/proveng/trunk/log/test.log`
    `echo "\n\n\n\n\n\n\n\n #{Time.now} test_ss_user_provisions_bb #{@user.username}\n\n\n\n\n" | cat >> /Users/lasto/clients/sage/branches/single_sign_on/log/test.log`
    `echo "\n\n\n\n\n\n\n\n #{Time.now} test_ss_user_provisions_bb #{@user.username}\n\n\n\n\n" | cat >> /var/log/drupal/drupal.log`
    
    
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
    # assert_logged_in_on_sbb(@user, @debug)

    unless @user.contains_text("Welcome,") && @user.link(:text, "#{@user.user.username.capitalize}").exist?
      $test_ui.agree('failed to be logged in on sbb?', true)
    end
    
    deny User.exists?(:sage_username => @user.username), "sage spark user provsisioning billingboss should not have a billingboss user account"
  
    @user.link(:text, /tools \& services/i).fire_event("onmouseover")
    @user.link(:text, /free tools/i).click
    
    assert_on_free_tools_page(@user, @debug)
    
    # click billing boss link
    @user.link(:text, /billing boss/i).click
  

    # click sign up link for billing boss
    @user.button(:value, /sign ?up/i).click

    assert_on_billing_info_page(@user, @debug) 
    
    user_fills_in_billing_info_form(@user)
    
    # click next button
    @user.button(:value, /next/i).click  

    assert_on_free_tool_summary_page(@user, @debug)    
    
    # click start using service now
    @user.link(:text, /start using your services now/i).click    

    assert_on_my_tools_and_services_page(@user, @debug)    

    # wait until access button exists
    started_waiting = Time.now
    Watir::Waiter.new(800).wait_until do
      if @user.contains_text("Access")
        true
      else
        sleep(5)
        @user.link(:text, /refresh/i).click         
        false
      end
    end
    
    puts "waited #{Time.now - started_waiting} seconds for provisioning. Well, I guess that's better than waiting #{Time.now + rand(10) - started_waiting + 1} seconds"
    assert User.exists?(:sage_username => @user.username), "billingboss account should exist after provisioning complete"
    #@debug = true 
    @user.goto Sage::Test::Server.billingboss.url
    # assert_logged_in_on_bb(@user, @debug)
    unless @user.link(:id, "logout-link").exist?
      puts "#{Time.now.to_s} user: #{@user.username} not logged in."
      $test_ui.agree('user seems to not be logged in?', true) 
    end

    # $test_ui.agree('on bb home page?', true) if @debug  
    # assert @user.link(:id, "logout-link").exist?, "log out link should exist after provisioning"

  end
  
 end