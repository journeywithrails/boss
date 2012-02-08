require File.dirname(__FILE__) + '/../../test_helper'
require 'service_provider/spsubscriptions_controller'

class ServiceProvider::SpsubscriptionsControllerTest < Test::Unit::TestCase  
  fixtures :spsubscriptions
  
  def setup
    @controller = ServiceProvider::SpsubscriptionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @spaccount = spaccounts(:inactive_account)
    set_http_authorization unless @method_name == "test_get_index_with_invalid_credentials"    
  end
  
  def teardown
  end  
  
  def test_should_get_index
    get :index, :spaccount_id => @spaccount.to_param
    assert_response :success
    assert_not_nil assigns(:spsubscriptions)
    assert_equal 2, assigns(:spsubscriptions).size, "There should be 2 spsubscriptions for the OneAccountName spaccount"
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

  def test_should_create_subscription
    assert_difference('Spsubscription.count') do
      post :create, :spaccount_id => @spaccount.to_param, 
           :spsubscription => {:service_code => 'ProductCode', :newqty => 1}
      assert_response 201
    end
    
    spacct = Spaccount.find(@spaccount.id)
    s = spacct.spsubscriptions.find_by_service_code('ProductCode')
    assert_equal 1, s.qty
  end

  def test_should_show_subscription
    get :show, :spaccount_id => @spaccount.to_param, :id => "Product1"
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :spaccount_id => @spaccount.to_param, :id => spsubscriptions(:inactive_subscription).to_param, :format => 'html'
    assert_response :success
  end

  def test_should_update_subscription
    put :update, :spaccount_id => @spaccount.to_param, 
        :id => spsubscriptions(:inactive_subscription).to_param, :status => 2
    assert_response :success
  end

  def test_should_destroy_subscription
    assert_difference('Spsubscription.count', -1) do
      delete :destroy, :spaccount_id => @spaccount.to_param, :id => spsubscriptions(:inactive_subscription).to_param
    end

    assert_response :success
  end
  
end


