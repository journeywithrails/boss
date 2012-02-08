require File.dirname(__FILE__) + '/../test_helper'
require 'session_controller'
# Re-raise errors caught by the controller.
class SessionController; def rescue_action(e) raise e end; end

class SessionControllerTest < Test::Unit::TestCase

  fixtures :users

  def setup
    @controller = SessionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def teardown
    $log_on = false
  end
  

# ssl is now controlled by setting in application.yml so there is no easy to turn SSL on and off
# during test.  
#  def test_should_login_with_ssl_on_production
#    old_env = ENV['RAILS_ENV']
#    ENV['RAILS_ENV'] = 'production'
#    get :new
#    assert_select "form[action=?]", "https://test.host/session"
#    ENV['RAILS_ENV'] = old_env
#  end
  
  protected
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
