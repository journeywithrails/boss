$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

require 'fileutils'

#test cases for user signup
class RemailActivationTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    ::AppConfig.activate_users = true
    @unactivated_user = watir_session.with(:unactivated_user)
    @unactivated_user.user.update_attribute(:email, @unactivated_user.autotest_email)
    @unactivated_user.start_email_server
    start_email_server
  end
  
  def teardown 
    @unactivated_user.end_email_server
    end_email_server
    @unactivated_user.teardown
  end
if ::AppConfig.activate_users  
  def test_remail_activation_from_login
    @unactivated_user.goto_home_url
    
    # first test clicking remail_activation with empty login
    assert @unactivated_user.link(:text, "Re-send activation").exists?    
    @unactivated_user.link(:text, "Re-send activation").click    
    @unactivated_user.assert_on_page '/remail_activation', 
      "clicking re-send activation on home login box should return a remail_activation action of users"
    assert @unactivated_user.text_field(:id, "user_login").exists?, 
      "after clicking re-send activation with an empty login, should still be a login input on remail_activation page"
    
    # second test clicking remail_activation with non-existant login
    @unactivated_user.goto_home_url
    assert @unactivated_user.text_field(:id, "login").exists?, 
      "home page should have a login box, and the login input is login not user[login]"
    @unactivated_user.text_field(:id, "login").set('non-existant@nowhere.com')
    @unactivated_user.link(:text, "Re-send activation").click    
    @unactivated_user.assert_on_page '/remail_activation', 
      "clicking re-send activation on home login box should return a remail_activation action of users"
    assert @unactivated_user.text_field(:id, "user_login").exists?, 
      "after clicking re-send activation with an incorrect login, should still be a login input on remail_activation page"
    @unactivated_user.assert_flash "We could not find a user with the email address non-existant@nowhere.com",
      "after clicking re-send activation with an incorrect login, should be a flash message"
      
    # now do it for real
    @unactivated_user.goto_home_url
    @unactivated_user.text_field(:id, "login").set(@unactivated_user.user.sage_username)
    @unactivated_user.link(:text, "Re-send activation").click    
    @unactivated_user.wait
    @unactivated_user.user.reload
    activation_code = @unactivated_user.user.activation_code
    
    @unactivated_user.assert_on_page '/remail_activation', 
      "clicking re-send activaton on home login box should return a remail_activation action of users"
    deny @unactivated_user.text_field(:id, "user_login").exists?, 
      "after clicking re-send activation with an correct login, the login field should go away"
    assert @unactivated_user.text.include?("email containing instructions on how to activate your account has been sent to #{@unactivated_user.user.sage_username}."),
      "after clicking re-send activation password with correct login, should tell user instructions have been mailed"
    
    check_activation_mail(activation_code)        
  end
  
  # replicates above, but enter the correct login on the remail_activation page rather than the home page
  def test_remail_activation_from_remail_activation_page
    @unactivated_user.goto_home_url
    # first test clicking remail_activation with empty login
    assert @unactivated_user.link(:text, "Re-send activation").exists?    
    @unactivated_user.link(:text, "Re-send activation").click    
    @unactivated_user.assert_on_page '/remail_activation', 
      "clicking re-send activation on home login box should return a remail_activation action of users"
    assert @unactivated_user.text_field(:id, "user_login").exists?, 
      "after clicking re-send activation with an empty login, should still be a login input on remail_activation page"
    @unactivated_user.text_field(:id, "user_login").set(@unactivated_user.user.sage_username)
    @unactivated_user.button(:id, 'remail_activation_button').click
    @unactivated_user.user.reload
    activation_code = @unactivated_user.user.activation_code
    
    @unactivated_user.assert_on_page 'users/remail_activation', 
      "clicking re-send activaton on home login box should return a remail_activation action of users"
    deny @unactivated_user.text_field(:id, "user_login").exists?, 
      "after clicking re-send activation with an correct login, the login field should go away"
    assert @unactivated_user.text.include?("email containing instructions on how to activate your account has been sent to #{@unactivated_user.user.sage_username}."),
      "after clicking re-send activation password with correct login, should tell user instructions have been mailed"
      
    check_activation_mail(activation_code)
  end
end  
  private

  def check_activation_mail(activation_code)
    mail = get_last_sent_email()
    activation_link = /http:\/\/.+\/activate\/#{activation_code}/.match(mail.body).to_s
    assert_not_nil activation_link,
      "the re-sent activation mail should contain an activation link"
    @unactivated_user.goto(activation_link)
  end

end
