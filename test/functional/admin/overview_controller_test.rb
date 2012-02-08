require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/overview_controller'

class Admin::OverviewControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :roles
  fixtures :roles_users
  def setup
    @controller = Admin::OverviewController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_requires_login
    logout
    get :index
    assert_redirected_to 'access/denied'
  end

  def test_disallows_non_admin
    login_as :basic_user
    get :index
    assert_response :redirect
  end
  
  def test_allows_generic_admin
    login_as :peon_admin_user
    get :index
    assert_response :success
  end
  
  def test_peon_admin_menu
    login_as :peon_admin_user
    get :index
    assert @response.body.include?("Admin home")
    deny @response.body.include?("Master admin")
    deny @response.body.include?("Feedback admin")
  end
  
  def test_master_admin_menu
    login_as :master_admin_user
    get :index
    assert @response.body.include?("Admin home")
    assert @response.body.include?("Master admin")
    assert @response.body.include?("Feedback admin")
  end

  def test_feedback_admin_menu
    login_as :feedback_admin_user
    get :index
    assert @response.body.include?("Admin home")
    deny @response.body.include?("Master admin")
    assert @response.body.include?("Feedback admin")
  end

end