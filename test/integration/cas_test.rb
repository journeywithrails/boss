require "#{File.dirname(__FILE__)}/../test_helper"
class CasTest < ActionController::IntegrationTest
  
  fixtures :users
  
  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  
  # def test_should_login_and_redirect_for_complete_profile
  #   
  #   flunk "not implemented"
  #   # post :create, :login => 'basic_user@billingboss.com', :password => 'test'
  #   # assert session[:user]
  #   # assert_response :success
  #   # assert @response.body.include?("Please wait...")
  # end
  # 
  # def test_should_login_and_check_for_logged_in_sucessfully
  #   flunk "not implemented"
  #   # post :create, :login => 'basic_user@billingboss.com', :password => 'test'
  #   # assert session[:user]
  #   # assert_response :success
  #   # assert_match(/Logged in successfully./, flash[:notice])    
  # end
  # 
  # def test_should_login_and_redirect_for_incomplete_profile
  #   flunk "not implemented"
  #   # post :create, :login => 'user_without_profile@billingboss.com', :password => 'test'
  #   # assert session[:user]
  #   # assert_response :success
  #   # assert @response.body.include?("Please wait...")
  # end
  # 
  # def test_should_logout
  #   flunk "not implemented"
  #   # login_as :basic_user
  #   # get :destroy
  #   # assert_nil session[:user]
  #   # assert_response :redirect
  # end
  # 
  # def test_redirect_for_admin
  #   flunk "not implemented"
  #   # u = User.find(:first, :conditions => {:login => "peon_admin_user@billingboss.com"})
  #   # u.profile.current_view = "admin"
  #   # u.profile.save!
  #   # u.save!
  #   # post :create, :login => 'peon_admin_user@billingboss.com', :password => 'test', :remember_me => "1"
  #   # assert_response :success
  #   # assert @response.body.include?("tabs/admin")
  #   # 
  # end
  # 
  # def test_redirect_for_bookkeeper
  #   flunk "not implemented"
  #   # u = User.find(:first, :conditions => {:login => "bookkeeper_user@billingboss.com"})
  #   # u.profile.current_view = "bookkeeper"
  #   # u.profile.save!
  #   # u.save!
  #   # post :create, :login => 'bookkeeper_user@billingboss.com', :password => 'test', :remember_me => "1"
  #   # assert_response :success
  #   # assert @response.body.include?("tabs/bookkeeper")    
  # end
  # 
  # 

  def new_user(options)
    user = open_session do |user|
      def user.scratch
        @scratch ||= OpenStruct.new
      end

    end
    user.scratch.options = options
    user
  end
  
end
