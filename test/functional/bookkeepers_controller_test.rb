require File.dirname(__FILE__) + '/../test_helper'
require 'bookkeepers_controller'

# Re-raise errors caught by the controller.
class BookkeepersController; def rescue_action(e) raise e end; end

  include Arts

class BookkeepersControllerTest < ActionController::TestCase
  fixtures :users  
  
  def setup
    
    # sign on with the bookkeeper user for the bookkeeping client report tests    
    if self.method_name == "test_should_allow_client_to_remove_bookkeeper" 
      login_as :user_has_bookkeeping_contract      
      @user = users(:user_has_bookkeeping_contract)
    else
      login_as :basic_user
      @user = users(:basic_user)
    end    
  end
  
  def teardown
    $log_on = false
  end

  def test_should_get_index
    @controller.stubs(:form_authenticity_token).returns('aaaa')    
    get :index
    assert_response :success
    assert @response.body.include?("Send email invitation to share data")
    assert_not_nil assigns(:bookkeepers)
    assert_not_nil assigns(:invitations)
  end

  def test_should_show_bookkeeper
    @controller.stubs(:form_authenticity_token).returns('aaaa')    
    get :show, :id => bookkeepers(:first_bookkeeper).id
    assert_response :success
  end
  
  def test_should_allow_client_to_remove_bookkeeper
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    User.any_instance.stubs(:has_no_role).returns(true)
    assert_difference('BookkeepingContract.count', -1) do
      delete :delete_contract, :id => 1
    end    
  end

end
