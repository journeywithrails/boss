require File.dirname(__FILE__) + '/../test_helper'
require 'tabs_controller'

class TabsControllerTest < ActionController::TestCase

  fixtures :users
  
  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  def test_should_get_biller_complete_profile
    Profile.any_instance.stubs(:is_complete?).returns(true)        
    login_as :basic_user
    get :biller
    assert_redirected_to :controller => 'invoices', :action => 'overview'
  end
  
  def test_should_get_biller_incomplete_profile
    Profile.any_instance.stubs(:is_complete?).returns(false)        
    login_as :basic_user
    get :biller
    assert_redirected_to :controller => 'profiles', :action => 'edit'
    assert_equal "Please take a moment to fill in your business information.", flash[:notice]        
  end

  def test_should_get_bookkeeper
    
    Profile.any_instance.stubs(:is_complete?).returns(true)    
    login_as :bookkeeper_user
   
    get :bookkeeper
    assert_redirected_to :controller => 'bookkeeping_clients', :action => 'index'
    get :biller
    assert_redirected_to :controller => 'invoices', :action => 'overview'    
    assert_nil flash[:notice]    
   
  end  
 
  
  def test_should_get_admin    
    login_as :feedback_admin_user
    get :admin
    assert_redirected_to :controller => '/admin/overview', :action => 'index'
  end  
  
end