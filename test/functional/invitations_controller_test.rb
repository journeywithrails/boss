require File.dirname(__FILE__) + '/../test_helper'

class InvitationsControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  def test_should_get_index
    login_as :wants_bookkeeper_user
    get :index
    assert_response :success
    assert_not_nil assigns(:invitations)
  end

end
