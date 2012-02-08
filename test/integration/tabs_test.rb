require "#{File.dirname(__FILE__)}/../test_helper"

class TabsTest < ActionController::IntegrationTest
  
fixtures  :users  
 
  def setup
  end

  def test_test_should_sign_up_as_bookkeeper_and_change_view
    @user = users(:bookkeeper_user)

    stub_cas_logged_in(@user)
    assert_equal :biller, @user.profile.current_view, "the current view should be biller"
    
    # switch to bookkeeper    
    get '/tabs/bookkeeper'
    assert_response :redirect
    follow_redirect!
    
    #reload user record and check profile current_view
    @user = User.find(@user.id)
    assert_equal :bookkeeper, @user.profile.current_view, "the current view should be bookkeeper"
    
    # get the client reports and check the profile current view has not changed
    get '/bookkeeping_clients/13/reports/invoice'
    assert_response :success          
    #reload user record and check profile current_view
    @user = User.find(@user.id)
    assert_equal :bookkeeper, @user.profile.current_view, "the current view should be bookkeeper after viewing client reports"    
    
  end
  
  def teardown
    super
  end
  
end
