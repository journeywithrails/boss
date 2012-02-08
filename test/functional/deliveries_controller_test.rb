require File.dirname(__FILE__) + '/../test_helper'
require 'deliveries_controller'

# Re-raise errors caught by the controller.
class DeliveriesController; def rescue_action(e) raise e end; end

class DeliveriesControllerTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @controller = DeliveriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :basic_user
    @invoice_with_no_customer = invoices(:invoice_with_no_customer)
    @user = users(:basic_user)
  end

  def teardown
    $log_on = false
  end

  def test_should_send_invoice_copy_to_user
    # $log_on = true
    i = @user.invoices.create
    customer = Customer.new(:name => 'Joe', :language => "fr")
    i.customer = customer

    Invoice.stubs(:find).returns(i)
    i.expects(:sendable?).returns(true)
    i.expects(:deliver!).returns(true)

    assert_difference('AccessKey.count',+2) do
      post :create, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param, :mail_name => 'send', :recipients => 'test@example.com', :mail_options => {:email_copy=>"on"} }
    end
    keys = AccessKey.find(:all, :limit=>2, :order=>"id DESC")
    assert_equal keys[1].not_tracked, nil, "first created key should be tracked"
    assert_equal keys[0].not_tracked, true, "second created key should not be tracked"

    assert_equal 'Email was successfully delivered.', flash[:notice]
  end
  
  def test_should_send_invoice_in_customers_locale
    # $log_on = true
    i = @user.invoices.create
    customer = Customer.new(:name => 'Joe', :language => "fr")
    i.customer = customer
    
    Invoice.stubs(:find).returns(i)
    i.expects(:sendable?).at_least_once.returns(true)
    i.expects(:deliver!).returns(true)
    
    post :create, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param, :mail_name => 'send', :recipients => 'test@example.com' }
    delivery = assigns(:delivery)
    assert_match /Une nouvelle facture de basic_user_profile_name/, delivery.subject
    assert_equal "fr", locale.language
    assert_equal 'Email was successfully delivered.', flash[:notice]
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:deliveries)
  end

  def test_should_redirect_to_unable_on_new_with_no_deliverable
    get :new
    assert_redirected_to unable_deliveries_path    
  end
  
  def test_should_redirect_to_unable_on_new_with_out_of_scope_deliverable
    u=users(:complete_user)
    i = u.invoices.create
    get :new, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param }
    assert_redirected_to unable_deliveries_path    
  end
  
  def test_should_redirect_to_unable_on_new_with_in_scope_but_not_sendable_deliverable
    i = @user.invoices.create
    Invoice.any_instance.stubs(:sendable?).returns(false)
    get :new, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param }
    assert_redirected_to unable_deliveries_path    
  end
  
  def test_should_get_new_with_in_scope_deliverable
    i = @user.invoices.create
    Invoice.any_instance.stubs(:sendable?).returns(true)
    get :new, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param }
    assert_response :success
    assert_equal assigns(:deliverable), i
  end
  
  def test_should_log_delivery
    @controller.stubs(:set_locale_from_customer).returns(:true)
    i = @user.invoices.create
    Invoice.stubs(:find).returns(i)
    i.expects(:sendable?).at_least_once.returns(true)
    i.expects(:deliver!).returns(true)
    
    assert_difference('Activity.count') do
      post :create, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param, :mail_name => 'send', :recipients => 'test@example.com' }
    end
  end
  
  def test_should_create_delivery
    @controller.stubs(:set_locale_from_customer).returns(:true)
    i = @user.invoices.create
    Invoice.stubs(:find).returns(i)
    i.expects(:sendable?).at_least_once.returns(true)
    i.expects(:deliver!).returns(true)


    assert_difference('Delivery.count') do
      post :create, :delivery => { :deliverable_type => 'Invoice', :deliverable_id => i.to_param, :mail_name => 'send', :recipients => 'test@example.com' }
    end
    
    assert_equal assigns(:deliverable), i

    assert_redirected_to invoice_path(i)
  end
  
  def test_should_show_delivery
    i = @user.invoices.create
    Invoice.stubs(:find).returns(i)
    get :show, :id => 1
    assert_response :success
  end
  
  def test_should_destroy_delivery
    assert_difference('Delivery.count', -1) do
      delete :destroy, :id => 1
    end
  
    assert_redirected_to deliveries_path
  end
  
  def test_should_get_new_with_api_token
    api_token = mock('api_token')
    invoice = SimplyAccountingInvoice.new
    customer = Customer.new(:name => 'Joe')
    delivery = Delivery.new
    delivery.deliverable = invoice
    delivery.stubs(:setup_mail_options)
    invoice.expects(:sendable?).at_least_once.returns(true)
    invoice.customer = customer
    api_token.expects(:delivery).at_least_once.returns(delivery)
    api_token.responds_like(ApiToken.new)
    api_token.stubs(:set_current_user)
    @controller.expects(:api_token?).at_least_once.returns(true)
    @controller.expects(:api_token).at_least_once.returns(api_token)

    get :new
    assert_response :success
    assert_equal assigns(:delivery), delivery
    assert_equal assigns(:deliverable), invoice
  end
end
