require File.dirname(__FILE__) + '/../test_helper'
require 'access_controller'

class AccessController; def rescue_action(e) raise e end; end

class AccessControllerTest < Test::Unit::TestCase

  fixtures :invoices, :invitations, :users, :access_keys
  
  def setup
    @controller = AccessController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def setup_access_for_invoice
    @item = invoices(:invoice_with_profile)
    @access_key = @item.create_access_key
  end

  def setup_access_for_bookkeeping_invitation
    bki = BookkeepingInvitation.create
    @item = bki
    @access_key = @item.create_access_key
  end

  # Replace this with your real tests.
  def test_should_get_access_for_invoice
    setup_access_for_invoice
    
    get :access, :access => @access_key
    assert_redirected_to :controller => 'invoices', :action => 'display_invoice', :id => @access_key
  end
  
  def test_access_fails_redirects_to_home
    setup_access_for_invoice

    AccessKey.any_instance.expects(:use?).returns(false)
    get :access, :access => @access_key
    assert_response :missing
  end
  
  def test_should_get_access_for_bookkeeping_invitation
    setup_access_for_bookkeeping_invitation
    
    get :access, :access => @access_key
    assert_redirected_to :controller => 'bookkeeping_invitations', :action => 'display_invitation', :id => @access_key
  end
  
  def test_should_render_404_on_bad_or_missing_ak
    setup_access_for_bookkeeping_invitation
    
    get :access
    assert_response 404
    
    get :access, :access => "asdf"
    assert_response 404
  end
  
  def test_should_not_toggle_access_key_if_not_logged_in
    stub_cas_logged_out
    
    ak = AccessKey.new(:valid_until => nil)
    ak.keyable = invoices(:invoice_with_no_customer)
    ak.save!
    
    put :toggle_access, :id => ak.id
    assert_equal 99999, ak.uses
    assert_response :redirect
  end
  
  def test_should_toggle_access
    @request.env["HTTP_REFERER"] = 'http://test.host/last/page/visited'
    login_as :basic_user
    ak = AccessKey.new(:valid_until => nil)
    ak.keyable = invoices(:invoice_with_no_customer)
    ak.save!
    
    put :toggle_access, :id => ak.id
    assert_response :redirect
  end
  
end
