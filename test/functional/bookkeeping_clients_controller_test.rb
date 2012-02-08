require File.dirname(__FILE__) + '/../test_helper'

class BookkeepingClientsControllerTest < ActionController::TestCase
  fixtures :users, :billers, :bookkeepers, :bookkeeping_contracts

  def setup
    login_as :bookkeeper_user
    @user = users(:bookkeeper_user)
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:bookkeeping_clients)
  end

#  def test_should_get_new
#    get :new
#    assert_response :success
#  end
#
#  def test_should_create_bookkeeping_clients
#    assert_difference('BookkeepingClients.count') do
#      post :create, :bookkeeping_clients => { }
#    end
#
#    assert_redirected_to bookkeeping_clients_path(assigns(:bookkeeping_clients))
#  end

  def test_should_show_bookkeeping_clients
    get :show, :id => billers(:biller_has_bookkeeping_contract)
    assert_response :success
  end

#  def test_should_get_edit
#    get :edit, :id => bookkeeping_clients(:one).id
#    assert_response :success
#  end
#
#  def test_should_update_bookkeeping_clients
#    put :update, :id => bookkeeping_clients(:one).id, :bookkeeping_clients => { }
#    assert_redirected_to bookkeeping_clients_path(assigns(:bookkeeping_clients))
#  end
#
  def test_should_destroy_bookkeeping_clients
    
    User.any_instance.stubs(:has_no_role).returns(true)    
    
    biller = billers(:biller_has_bookkeeping_contract)
    assert_difference('BookkeepingContract.count', -1) do
      delete :destroy, :id => biller.id
    end

    assert_redirected_to bookkeeping_clients_path
  end
end
