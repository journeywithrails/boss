require "#{File.dirname(__FILE__)}/../test_helper"
require 'hpricot'

class SignupBrowsalFlowTest < ActionController::IntegrationTest

  # Tests Flow 3a (from 'What is this?' link) -> 3d -> 4c -> 4d
  def test_user_clicks_what_is_this
    current_url = nil
    api_token = nil
    token_url = nil

    extended_session do |api|
      assert_difference('ApiToken.count') do
        # without http auth
         api.post '/browsals', :simply_request => {
            :browsal => {:browsal_type => 'SignupBrowsal', :start_status => 'signup' },
          }, :format => 'xml'
      end
      api.assert_response :created 
      token_url = api.response.headers['Location']
      api_token = ApiToken.last
      current_url = api.current_url
      assert_not_nil current_url
      assert_match %r{^http://[^/]*/browsals/#{ api_token.guid }/signup$}, current_url
    end
    
    extended_session do |user|
      user.get current_url
      user.assert_redirected_to_sam(:theme=>'simply', :service_url => "http://#{host_for_test}/api/simply/newuser/thankyou")
      # don't actually go to sam, assume user was created and auto-logged in
      stub_cas_first_login('brand_new_user', 'brand_new_user@billingboss.com', 'billingboss/simply')
      service_url = sam_service_url_from_redirect_url(user.redirect_to_url)
      user.get service_url
      user.assert_template 'users/simply/thankyou'
      user.assert_tag :a, :attributes => { :id => 'continue-button'}

      api_token.reload
      assert_equal  User.find_by_sage_username("brand_new_user"),
                    api_token.user,
                    "api_token.user should be set to the new user"

      xml = user.received_complete!(token_url)

      api_token.reload
      assert_equal  "simply:signup:received_complete",
                    api_token.mode,
                    "api_token.mode should include fired_event"

      deny          xml.search("/signup-browsal/user").empty?, 
                    "user node should exist after login"

      assert_equal  "brand_new_user", 
                    xml.search("/signup-browsal/user/login").text,
                    "login does not match logged in user"
    end
    
    
  end
  
  def test_login_flow
    unstub_cas
    CASClient::Frameworks::Rails::Filter.stubs(:check_cas_status?).returns(false)
    current_url = nil
    api_token = nil
    token_url = nil

    extended_session do |api|
      assert_difference('ApiToken.count') do
        # without http auth
         api.post '/browsals', :simply_request => {
            :browsal => {:browsal_type => 'SignupBrowsal', :start_status => 'login' },
          }, :format => 'xml'
      end
      api.assert_response :created
      token_url = api.response.headers['Location']
      
      api_token = ApiToken.last
      current_url = api.current_url
      assert_not_nil current_url
      assert_match %r{^http://[^/]*/browsals/#{ api_token.guid }/login$}, current_url
    end
    
    extended_session do |user|
      user.get current_url
      user.assert_redirected_to_cas_login
      user.assert_cas_service_url_matches %r{#{api_token.service_url_prefix}/session/logged_on}
      stub_cas_logged_in(users(:basic_user))
      user.get '/session/logged_on'

      api_token.reload
      assert_equal users(:basic_user), api_token.user

      xml = user.received_complete!(token_url)

      api_token.reload
      assert_equal  "simply:login:received_complete",
                    api_token.mode,
                    "api_token.mode should include fired_event"

      deny          xml.search("/signup-browsal/user").empty?, 
                    "user node should exist after login"

      assert_equal  "basic_user", 
                    xml.search("/signup-browsal/user/login").text,
                    "login does not match logged in user"
    end

    

  end
  
  
end
