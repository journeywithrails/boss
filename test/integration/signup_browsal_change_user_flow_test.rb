require "#{File.dirname(__FILE__)}/../test_helper"

class SignupBrowsalChangeUserFlowTest < ActionController::IntegrationTest
  include SimplyApiTestHelpers

  def test_user_clicks_use_a_different_account
    unstub_cas
    api_token, current_url, token_url = initiate_signup('login', :authorized)
    assert_equal "basic_user@billingboss.com", api_token.simply_username
    extended_session do |user|
      user.simulate_login!(current_url, users(:complete_user))
      user.get current_url
      user.assert_redirected_to '/session/logged_on'
      user.follow_redirect!
      assert_equal users(:complete_user), user.current_user
      user.assert_template 'session/simply/logged_on'
      user.assert_tag :a, :attributes => { :id => 'continue-button'}
      xml = user.received_complete!(token_url)
      api_token.reload
      assert_equal  "simply:login:received_complete",
                    api_token.mode,
                    "api_token.mode should include fired_event"

      deny          xml.search("/signup-browsal/user").empty?, 
                    "user node should exist after login"

      assert_equal  "complete_user", 
                    xml.search("/signup-browsal/user/login").text,
                    "login does not match logged in user"
    end
  end
end
