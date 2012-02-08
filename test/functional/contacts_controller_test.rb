require File.dirname(__FILE__) + '/../test_helper'
require 'contacts_controller'

# Re-raise errors caught by the controller.
class ContactsController; def rescue_action(e) raise e end; end

class ContactsControllerTest < Test::Unit::TestCase
  fixtures :customers
  fixtures :contacts
  fixtures :users
  
  include Arts

  def setup
    @controller = ContactsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :basic_user
    @customer = customers(:customer_with_contacts)
  end

  def test_should_get_index
    get :index, :customer_id => @customer.id
    assert_response :success
    assert_not_nil assigns(:contacts)
  end

  def test_should_create_contact
    assert_difference('Contact.count') do
      post :create, :customer_id => @customer.id, :contact => valid_contact_attributes
    end

    assert_redirected_to customer_contact_path(:customer_id => @customer.id, :id => assigns(:contact))
  end

  def test_should_update_contact
    put :update, :customer_id => @customer.id, :id => 1, :contact => valid_contact_attributes
    assert_redirected_to customer_contact_path(:customer_id => @customer.id, :id => assigns(:contact))
  end
  
  def test_get_index_rjs
    xhr :get, :index, :customer_id => 2
    assert assigns(:contacts)    
    assert_rjs :replace_html, "contacts_container"
   end  

  def valid_contact_attributes
    {:email => 'valid@email.com'}
  end
end
