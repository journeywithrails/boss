$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'

class ContestTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  def setup
    @user = watir_session.with(:user_without_profile)
  end
  
  def teardown
    @user.teardown
  end
if ::AppConfig.contest.bybs  
  def test_signup_contest
    b = @user.b
    @user.logs_out
    @user.goto_contest_url
    b.wait
    @user.link(:class, "entry_button").click
    b.wait
    assert_difference ("User.count") do
      @user.text_field(:id, "user_login").set "test"
      @user.text_field(:id, "user_email").set "test@test.com"
      @user.text_field(:id, "user_password").set "test@test.com"
      @user.text_field(:id, "user_password_confirmation").set "test@test.com"
      @user.checkbox(:id, "user_terms_of_service").set true
      @user.button(:id, "register_button").click
      b.wait
    end
  end
  
  def test_taf_contest
    b = @user.b
    @user.goto_contest_taf_url
    b.wait    
    @user.button(:id, "referral_submit").click
    b.wait
    assert b.html.include?("You have not invited any friends.")
    assert b.html.include?("yui-t7")
    
    @user.text_field(:id, "referral_referrer_name").set "Me"
    @user.text_field(:id, "referral_referrer_email").set "me@me.com"
    @user.text_field(:id, "referral_friend_name_1").set "You"
    @user.text_field(:id, "referral_friend_email_1").set "you@you.com"    
    @user.button(:id, "referral_submit").click    
    b.wait
    
    assert b.html.include?("Thank you for helping to spread the word about Billing Boss")
    assert b.html.include?("yui-t7")
  end
end
end
