$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test'
require File.dirname(__FILE__) + '/acceptance_test_helper'

class RacContestTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  def setup
    @user = watir_session.with(:user_without_profile)
  end
  
  def teardown
    @user.teardown
  end
if ::AppConfig.contest.rac  

  def test_front_page_and_routes_check
    b = @user.b
    @user.goto_rac_contest_url
    assert b.html.include?("Help your clients take control")
    @user.goto_rac_contest_tell_a_client_url
    assert b.html.include?("Send your clients")
  end

  def test_login_and_redirect
    b = @user.b
    @user.goto_rac_contest_url
    #bad user
    @user.link(:id, 'login_link').click
    b.wait
    @user.text_field(:id, 'login').set "garbage"
    @user.button(:id, 'login_button').click
    b.wait
    assert b.html.include?("Please enter a valid login and password")
    assert b.html.include?("already have a Billing Boss")

    #ok
    @user.text_field(:id, 'login').set "basic_user@billingboss.com"
    @user.text_field(:id, 'password').set "test"
    @user.button(:id, 'login_button').click
  
    b.wait
    assert b.html.include?("Send your clients an email")    
  end
  
  def test_signup_and_redirect
    b = @user.b
    @user.goto_rac_contest_url
    #bad user
    @user.link(:id, 'enter_link').click
    b.wait
    @user.text_field(:id, 'user_login').set "test@billingboss.com"
    @user.button(:id, 'register_button').click
    b.wait
    assert b.html.include?("prohibited this user from being saved")

    #bad profile
    @user.text_field(:id, 'user_login').set "test@billingboss.com"
    @user.text_field(:id, 'user_password').set "test"
    @user.text_field(:id, 'user_password_confirmation').set "test"
    @user.checkbox(:id, 'user_terms_of_service').set(true)
    @user.button(:id, 'register_button').click
    b.wait
    assert b.html.include?("prohibited this profile from being saved")
    
    #ok
    @user.text_field(:id, 'user_login').set "test@billingboss.com"
    @user.text_field(:id, 'user_password').set "test"
    @user.text_field(:id, 'user_password_confirmation').set "test"
    @user.checkbox(:id, 'user_terms_of_service').set(true)
    @user.text_field(:id, 'profile_company_name').set "test"
    @user.text_field(:id, 'profile_contact_name').set "test"
    @user.text_field(:id, 'profile_company_address1').set "test"
    @user.text_field(:id, 'profile_company_city').set "test"
    @user.text_field(:id, 'profile_company_state').set "test"
    @user.text_field(:id, 'profile_company_postalcode').set "test"
    @user.text_field(:id, 'profile_company_phone').set "test"
    @user.button(:id, 'register_button').click
    b.wait
    assert b.html.include?("Send your clients")    
  end
  
  def test_refer_a_client_recognition
    b = @user.b
    @user.logs_in
    #not logged in both pages check
    @user.goto_rac_contest_tell_a_client_url
    b.wait
    deny b.html.include?("You have not signed up or logged in")
    @user.goto("#{::AppConfig.host}/rac_contest/tell_a_client_accepted")
    b.wait

    deny b.html.include?("to Billing Boss now")
    assert b.html.include?("For each referral you send")

    
    @user.logs_out
    @user.goto_rac_contest_tell_a_client_url
    b.wait
    assert b.html.include?("You have not signed up or logged in")
    @user.goto("#{::AppConfig.host}/rac_contest/tell_a_client_accepted")
    b.wait
    assert b.html.include?("to Billing Boss now")
    deny b.html.include?("For each referral you send")
  end
  
  #  def test_signup_contest
  #    b = @user.b
  #    @user.logs_out
  #    @user.goto_contest_url
  #    b.wait
  #    @user.link(:class, "entry_button").click
  #    b.wait
  #    assert_difference ("User.count") do
  #      @user.text_field(:id, "user_login").set "test@test.com"
  #      @user.text_field(:id, "user_password").set "test@test.com"
  #      @user.text_field(:id, "user_password_confirmation").set "test@test.com"
  #      @user.checkbox(:id, "user_terms_of_service").set true
  #      @user.button(:id, "register_button").click
  #      b.wait
  #    end
  #  end
  #  
  #  def test_taf_contest
  #    b = @user.b
  #    @user.goto_contest_taf_url
  #    b.wait    
  #    @user.button(:id, "referral_submit").click
  #    b.wait
  #    assert b.html.include?("You have not invited any friends.")
  #    assert b.html.include?("yui-t7")
  #    
  #    @user.text_field(:id, "referral_referrer_name").set "Me"
  #    @user.text_field(:id, "referral_referrer_email").set "me@me.com"
  #    @user.text_field(:id, "referral_friend_name_1").set "You"
  #    @user.text_field(:id, "referral_friend_email_1").set "you@you.com"    
  #    @user.button(:id, "referral_submit").click    
  #    b.wait
  #    
  #    assert b.html.include?("Thank you for helping to spread the word about Billing Boss")
  #    assert b.html.include?("yui-t7")
  #  end
  end
end