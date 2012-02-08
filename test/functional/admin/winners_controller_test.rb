require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/winners_controller'
class Admin::WinnersControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :roles
  fixtures :roles_users
  fixtures :winners
  
  def setup
    @controller = Admin::WinnersController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    logout
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
  
  def test_disallows_admin_without_feedback_admin_role
    login_as :peon_admin_user
    get :index
    assert_response :redirect

  end
  
  def test_allows_master_admin
    login_as :master_admin_user
    get :index
    assert_response :success

  end
  
  def test_allows_winners_admin
    login_as :winners_admin_user
    get :index
    assert_response :success
  end
  
  def test_get_menu
    login_as :winners_admin_user
    get :index
    assert @response.body.include?("Select which")   
  end

  def test_submit_winners
    w = Winner.new
    w.signup_type = "ssan"
    w.draw_date = Date.today
    w.winner_name = "John Smith"
    w.prize = "Monitor"
    w.save!
    
    w2 = Winner.new
    w2.signup_type = "soho"
    w2.draw_date = Date.today
    w2.winner_name = "Mary Doe"
    w2.prize = "Flash Memory"
    w2.save!
    
    assert_equal 2, Winner.count
    
    login_as :winners_admin_user
    get :index, :signup_type => "soho"
    post :create, :winners => {
                                "0" => {:draw_date => Date.today,
                                        :prize => "Item 1", 
                                        :winner_name => "Bob"
                                        },
                                "1" => {:draw_date => Date.today,
                                        :prize => "Item 2", 
                                        :winner_name => "Bob2"
                                        }
                                
                               }, "signup_type" => "soho"

    assert_equal 3, Winner.count
    assert !Winner.find(:first, :conditions => {:winner_name => "Bob"}).nil?
    assert !Winner.find(:first, :conditions => {:winner_name => "John Smith"}).nil?
    deny !Winner.find(:first, :conditions => {:winner_name => "Mary Doe"}).nil?
  end

end