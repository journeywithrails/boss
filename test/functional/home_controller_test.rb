require File.dirname(__FILE__) + '/../test_helper'

class HomeControllerTest < ActionController::TestCase
  fixtures :users
  def setup
    logout
    @controller = HomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  def teardown
    
  end
  
  def test_homepage_content_logged_out
    get :index
    assert_response :success
    assert @response.body.include?("free online invoicing")
    deny @response.body.include?("basic_user")
    assert @response.body.include?("Log In")
    assert @response.body.include?("Quick")
    assert @response.body.include?("Send your friends")
    assert @response.body.include?("Sage")
  end
  
  def test_homepage_content_logged_in
   # login_as :basic_user
   # get :index
   # assert @response.body.include?("basic_user")
   # deny @response.body.include?("Log In")
    
  end
  
  def test_mobile_request_not_recognized_if_not_present
    get :index
    assert_equal nil, session[:mobile_browser]
    deny @response.body.include?("Switch to non-mobile version")
  end
  
  def test_mobile_request_recognized_if_present
    @request.user_agent = "Mozilla/5.0 (iPod; U; CPU iPhone OS 2_1 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5F137 Safari/525.20"
    get :index
    assert_equal true, session[:mobile_browser]
    assert @response.body.include?("Switch to non-mobile version")
  end

  def test_user_param_request_overrides_existing_mobile_session
    @request.user_agent = "Mozilla/5.0 (iPod; U; CPU iPhone OS 2_1 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5F137 Safari/525.20"
    get :index
    assert @response.body.include?("Switch to non-mobile version")
    @response   = ActionController::TestResponse.new
    
    get :index, :mobile => "false"
    assert_equal false, session[:mobile_browser]
    deny @response.body.include?("Switch to non-mobile version")
  end
  
  def test_user_param_sets_new_mobile_session
    get :index, :mobile => "false"
    assert_equal false, session[:mobile_browser]
    deny @response.body.include?("Switch to non-mobile version")
  end
  
  def test_mobile_version_has_footer_link_to_switch_to_regular_version
    get :index, :mobile => "true"
    assert @response.body.include?("Switch to non-mobile version")
  end
  
  def test_mobile_version_has_no_footer_link_to_switch_to_regular_version
    get :index
    deny @response.body.include?("Switch to non-mobile version")
  end  
  
end
