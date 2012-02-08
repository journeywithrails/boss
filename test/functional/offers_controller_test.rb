require File.dirname(__FILE__) + '/../test_helper'

class OffersControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  def test_should_get_index
    login_as :bookkeeper_user
    get :index
    assert_response :success
    assert_not_nil assigns(:offers)
  end

end
