require File.dirname(__FILE__) + '/../../test_helper'
require 'service_provider/spaccounts_controller'

class ServiceProvider::SpaccountsControllerTest < ActiveSupport::TestCase
  fixtures :spaccounts
  
  def setup
    @controller = ServiceProvider::SpaccountsController.new    
    @request    = ActionController::TestRequest.new    
    @response   = ActionController::TestResponse.new 
    # don't set valid http auth for the invalid credential test
    set_http_authorization unless @method_name == "test_get_index_with_invalid_credentials"
  end
  
  def teardown
    $log_on = false
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:spaccounts)
  end
  
  def test_get_index_with_invalid_credentials
    set_http_authorization("wrong", "wrong")
    get :index
    assert_response 401
    assert_nil assigns(:spaccounts)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_not_create_empty_account
    assert_no_difference('Spaccount.count') do
      post :create, :spaccount => {}
      assert_response 422
    end

  end

  def test_should_create_account
    assert_difference('Spaccount.count') do
      post :create, :format => 'xml', :spaccount => {:spaccount_name => 'NewAccount', :email =>'email@test.com', :password => 'unused'}
      assert_response 201
    end
    
    spacct = Spaccount.find('NewAccount')
    deny spacct.user.active, "User should be inactive when account is created."
    assert_no_match /password/, @response.body, 'response should not contain password field.'
  end

  def test_should_show_account
    get :show, :id => spaccounts(:inactive_account).id
    assert_response :success
    assert_no_match /password/, @response.body, 'response should not contain password field.'
  end

  def test_should_get_edit
    get :edit, :id => spaccounts(:inactive_account).id, :format => 'html'
    assert_response :success
  end

  def test_should_update_account
    put :update, :id => spaccounts(:inactive_account).id, :spaccount => {}
    assert_response :success
  end

  def test_should_destroy_account
    assert_difference('Spaccount.count', -1) do
      assert_difference('Spsubscription.count', -2) do
        delete :destroy, :id => spaccounts(:inactive_account).id
        assert_response :success
      end
    end
  end
  
end
