require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/master_controller'

class Admin::MasterControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :roles
  fixtures :roles_users
  def setup
    @controller = Admin::MasterController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_requires_login
    get :index
    assert_response :redirect

  end

  def test_disallows_non_admin
    login_as :basic_user
    get :index
    assert_response :redirect

  end
  
  def test_disallows_admin_without_master_admin_role
    login_as :peon_admin_user
    get :index
    assert_response :redirect

  end
  
  def test_allows_master_admin
    login_as :master_admin_user
    get :index
    assert_response :success

  end
  
  
end