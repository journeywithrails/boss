$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

class HomepageAcceptanceTest < SageAccepTestCase
  include AcceptanceTestSession
    
  def setup
    @basic_user = watir_session.with(:basic_user)
    @basic_user.logs_in    
    start_email_server
  end
  
  def teardown 
    end_email_server
    @basic_user.teardown
  end

  def test_submit_referral_on_front_page
    b = @basic_user.b
    @basic_user.goto("#{::AppConfig.host}/")
    b.wait
    assert_difference 'Referral.count' do
      @basic_user.text_field(:id, "referral_referrer_name").set("me")
      @basic_user.text_field(:id, "referral_referrer_email").set("me@abc.com")
      @basic_user.text_field(:id, "referral_friend_name_1").set("you")
      @basic_user.text_field(:id, "referral_friend_email_1").set("you@abc.com")
      @basic_user.button(:id, "referral_submit").click
      b.wait
    end
    assert @basic_user.html.include?("Thank you for helping")
  end
end