require File.dirname(__FILE__) + '/../test_helper'
require 'line_items_controller'

# Re-raise errors caught by the controller.
class LineItemsController; def rescue_action(e) raise e end; end

class LineItemsControllerTest < Test::Unit::TestCase
  fixtures :line_items
  fixtures :invoices
  fixtures :users

  def setup
    @controller = LineItemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :basic_user
    @invoice = invoices(:invoice_with_no_customer)
  end

  def test_should_get_index
    get :index, :invoice_id => @invoice.id
    assert_response :success
    assert_not_nil assigns(:line_items)
  end

  def test_should_get_new
    get :new, :invoice_id => @invoice.id
    assert_response :success
  end

  def test_should_create_line_item
    assert_difference('LineItem.count') do
      post :create, :invoice_id => @invoice.id, :line_item => { }
    end

    assert_redirected_to invoice_line_item_path(:invoice_id => @invoice.id, :id => assigns(:line_item))
  end

  def test_should_show_line_item
    get :show, :invoice_id => @invoice.id, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :invoice_id => @invoice.id, :id => 1
    assert_response :success
  end

  def test_should_update_line_item
    put :update, :invoice_id => @invoice.id, :id => 1, :line_item => { }
    assert_redirected_to invoice_line_item_path(:invoice_id => @invoice.id, :id => assigns(:line_item))
  end

  def test_should_destroy_line_item
    assert_difference('LineItem.count', -1) do
      delete :destroy, :invoice_id => @invoice.id, :id => 1
    end

    assert_redirected_to invoice_line_items_path(:invoice_id => @invoice.id)
  end
end
