require File.dirname(__FILE__) + '/../test_helper'
require 'payments_controller'

# Re-raise errors caught by the controller.
class PaymentsController; def rescue_action(e) raise e end; end

class PaymentsControllerTest < Test::Unit::TestCase
  fixtures :invoices
  fixtures :customers
  fixtures :users
  fixtures :line_items
  fixtures :payments
  fixtures :pay_applications

  #RADAR: tests that expect a transaction to fail must be included in this list,
  #       because rails does not support nested transactions.
  uses_transaction :test_should_fail_manual_payment_during_authorization,
                   :test_should_refuse_manual_payment_on_already_paid_invoice
  
  def setup
    @controller = PaymentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :user_for_payments
    #@invoice_with_no_customer = invoices(:invoice_with_no_customer)
    @user = users(:user_for_payments)
  end

  def teardown
    logout
    $log_concurrency = false
  end
  
  def test_should_get_index
    assert_raises Exception, "should not show payment screen without an invoice and customer" do
      get :new
    end
  end

  def test_should_get_new
    assert_raises Exception, "should not show payment screen without an invoice" do
      get :new
    end
  end

  def test_should_log_payment
    assert_difference('Activity.count') do
      post :create, :payment => {
        :customer_id => customers(:customer_for_payments).id,
        :invoice_id => invoices(:unpaid_invoice_1).id,
        :pay_type => 'cash',
        :amount => invoices(:unpaid_invoice_1).total_amount,
        :created_by_id => users(:user_for_payments).id }
    end
  end
  
  def test_should_log_payment_update
    assert_difference('Activity.count') do
      put :update, :id => 10, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 70.0, :created_by_id => 6 }
    end
  end
  
  def test_should_log_payment_delete
    assert_difference('Activity.count') do
      delete :destroy, :id => 10
    end
  end
  
  def test_should_not_create_payment_without_customer
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do
        assert_raises Exception, "should not create payment without customer" do
         post :create, :payment => { :pay_type => 'cash', :amount => 1.0, :created_by_id => 6 }
        end
      end
    end
  end

  def test_should_not_create_payment_for_another_user
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do
        assert_raises Sage::BusinessLogic::Exception::Error, "should not create payment for another user" do
         post :create, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 1.0, :created_by_id => 1 }
        end
      end
    end
  end

  def test_should_not_edit_another_users_payment
    logout
    login_as :basic_user
    assert_raises ActiveRecord::RecordNotFound, "should not show another user's payment" do
      get :edit, :id => 4
    end
  end
  
  def test_should_reject_overpayment
    put :update, :id => 10, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 150, :created_by_id => 6 }
    assert @response.body.include?("amount is greater than")
    p = Payment.find(10)
    pa = PayApplication.find(10)
    assert_equal 50.0, p.amount
    assert_equal 50.0, pa.amount
  end

  def test_should_update_cached_attributes_after_payment_updated
    put :update, :id => 10, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 30, :created_by_id => 6 }
    i = Invoice.find(75)
    assert_equal 30.0, i.paid_amount
    assert_equal 70.0, i.owing_amount
  end
  
  def test_should_update_cached_attributes_after_payment_recorded
        post :create, :payment => {
          :customer_id => customers(:customer_for_payments).id,
          :invoice_id => invoices(:unpaid_invoice_1).id,
          :pay_type => 'cash',
          :amount => invoices(:unpaid_invoice_1).total_amount,
          :created_by_id => users(:user_for_payments).id }

   # assert_redirected_to payment_path(assigns(:payment))
    i = Invoice.find(invoices(:unpaid_invoice_1))
    assert_equal 0, i.owing_amount;
    assert_equal i.total_amount, i.paid_amount
  end
  
  def test_should_show_payment_with_associated_invoice_i               
    get :edit, :id => payments(:full_payment_for_fully_paid_invoice).id
    assert_response :success
    assert_select 'span[name=unique]', invoices(:fully_paid_invoice).unique_name
  end

  def test_should_get_edit
    get :edit, :id => 10
    assert_response :success
  end

  def test_should_update_payment
    put :update, :id => 10, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 70.0, :created_by_id => 6 }
    assert_response :redirect
    p = Payment.find(10)
    pa = PayApplication.find(10)
    assert_equal 70.0, p.amount
    assert_equal 70.0, pa.amount
  end

  def test_should_destroy_payment
    assert_difference('Payment.count', -1) do
      delete :destroy, :id => 10
    end

    assert_response :redirect
  end

  def test_should_destroy_payment_and_update_invoice
    p = payments(:full_payment_for_fully_paid_invoice)
    amount_owing = p.amount
    i = p.invoices.first
    assert_not_nil i
    
    assert_difference('Payment.count', -1) do
      delete :destroy, :id => p.id
    end

    amount_paid = i.total_amount - amount_owing
    assert_equal amount_owing, i.amount_owing
    assert_equal amount_paid, i.paid_amount
  end
  
  def test_should_not_destroy_other_users_payment
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do 
        assert_raises Exception, "should not destroy another user's payment" do
          delete :destroy, :id => 4
        end
      end
    end
  end
  
  #user story 67, trac #44: Record non-online payments from customers
  
  #test for state transitions
  #  test invoice set to paid after outstanding amount is paid.
  #  test invoice set to acknowleged after when invoice is not fully paid.
  def test_should_set_invoice_paid
    assert_difference('Payment.count') do
      assert_difference('PayApplication.count') do
        post :create, :payment => {
          :customer_id => customers(:customer_for_payments).id,
          :invoice_id => invoices(:unpaid_invoice_1).id,
          :pay_type => 'cash',
          :amount => invoices(:unpaid_invoice_1).total_amount,
          :created_by_id => users(:user_for_payments).id }
      end
    end

   # assert_redirected_to payment_path(assigns(:payment))
    i = Invoice.find(invoices(:unpaid_invoice_1))
    assert_equal 0, i.amount_owing;
    assert i.fully_paid?
    assert i.paid?
  end
  
  def test_should_set_invoice_acknowleged
    assert_difference('Payment.count') do
      assert_difference('PayApplication.count') do
        post :create, :payment => {
          :customer_id => customers(:customer_for_payments).id,
          :invoice_id => invoices(:unpaid_invoice_1).id,
          :pay_type => 'cash',
          :amount => (invoices(:unpaid_invoice_1).total_amount-1),
          :created_by_id => users(:user_for_payments).id }
      end
    end

#    assert_redirected_to payment_path(assigns(:payment))
    i = Invoice.find(invoices(:unpaid_invoice_1))
    assert_equal 1, i.amount_owing;
    assert !i.fully_paid?
    assert_state i, :acknowledged
  end

  #test for failing manual payment during paypal authorization
  #  test redirect to failure page if any payment for the invoice is authorizing.
  #  We can manually send the authorize event before posting a payment.
  def test_should_fail_manual_payment_during_authorization
    p = @user.payments.build(
      :pay_type => "cash",
      :amount => "500.00",
      :date => "2007-11-14",
      :description => 'Partial payment of $500 cash.',
      :customer_id => customers(:customer_for_payments).id
    )
    p.save!
    pa = p.pay_applications.create(
      :amount => "500.00",
      :invoice_id => invoices(:unpaid_invoice_1).id
    )
    i = Invoice.find(invoices(:unpaid_invoice_1))
    amt_owing = i.amount_owing
    
    Payment.any_instance.stubs(:in_progress?).returns(true)
    
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do
        post :create, :payment => {
          :customer_id => customers(:customer_for_payments).id,
          :invoice_id => invoices(:unpaid_invoice_1).id,
          :pay_type => 'cash',
          :amount => invoices(:unpaid_invoice_1).total_amount,
          :created_by_id => users(:user_for_payments).id }
      end
    end

    assert_template('payments/new')
    i.reload
    assert_equal amt_owing, i.amount_owing
  end

  def test_should_refuse_manual_payment_on_already_paid_invoice
    i = Invoice.find(invoices(:fully_paid_invoice))
    assert_equal 0, i.amount_owing
    assert_no_difference('Payment.count') do #('Payment.count_by_sql("SELECT COUNT(*) FROM Payments")') do
      assert_no_difference('PayApplication.count') do
        post :create, :payment => {
          :customer_id => customers(:customer_for_payments).id,
          :invoice_id => invoices(:fully_paid_invoice).id,
          :pay_type => 'cash',
          :amount => 1,
          :created_by_id => users(:user_for_payments).id }
      end
    end
    assert_not_nil flash[:warning]
  end

  #test edit payment should delete and recreate associated pay application.
  # multiple pay applications are not covered in this test.
  # They should be dealt with when we allow overpayment to be applied to other invoices.
  def test_should_delete_and_recreate_pay_application_on_update
    #TODO: when user story for update payments is implemented
  end

  def test_should_not_show_other_peoples_payments
    u = users(:basic_user)
    p= u.payments.create(:customer => u.customers.first, :amount => 100, :pay_type => Payment::PayBy.first )    
    assert_raises ActiveRecord::RecordNotFound do
      get :edit, :id => p
    end
    assert_raises ActiveRecord::RecordNotFound do
      get :update, :id => p
    end
  end
  
  def test_editing_payment_to_lesser_amount_should_make_invoice_outstanding
    i = invoices(:fully_paid_invoice)
        put :update, :id => payments(:full_payment_for_fully_paid_invoice).id, :payment => {
          :amount => 5,}
     i.reload
     assert_equal "acknowledged", i.status
          
  end

  def test_disallow_overpaying_invoice
    i = invoices(:unpaid_invoice_1)
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do
        post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount => i.amount_owing+0.001, :created_by_id => users(:user_for_payments).id }
      end
    end
    assert @response.body.include?("greater than")
  end

  def test_allow_close_to_fullpayment_invoice
    i = invoices(:unpaid_invoice_1)
    assert_difference('Payment.count', 1) do
      assert_difference('PayApplication.count', 1) do
        post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount => i.amount_owing-0.001, :created_by_id => users(:user_for_payments).id }
      end
    end
  end

  #test for potential rounding problem
  def test_rounding_issue1
    i = invoices(:unpaid_invoice_4)
    assert_difference('Payment.count', 1) do
      assert_difference('PayApplication.count', 1) do
        post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount =>'321.0', :created_by_id => users(:user_for_payments).id }
      end
    end
  end

  def test_rounding_issue2
    i = invoices(:unpaid_invoice_5)
    assert_difference('Payment.count', 1) do
      assert_difference('PayApplication.count', 1) do
        post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount => '321.33', :created_by_id => users(:user_for_payments).id }
      end
    end
  end

  def test_disallow_submitting_zero_payment_amount
    i = invoices(:unpaid_invoice_1)
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do   
        post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount => 0, :created_by_id => users(:user_for_payments).id }
      end
    end
    assert @response.body.include?("zero")    
  end
  
  def test_created_payment_without_invoice_should_give_error
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do     
        assert_raises Exception, "should not create payment without invoice" do
          post :create, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 1.0, :created_by_id => users(:user_for_payments).id }
        end
      end
    end
  end
  
  def test_disallow_submitting_on_paid_invoice
    i = invoices(:fully_paid_invoice)
    assert_no_difference('Payment.count') do
      assert_no_difference('PayApplication.count') do   
        post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount => 1.0, :created_by_id => users(:user_for_payments).id }
      end
    end
    assert @response.body.include?("Submitted payment amount is greater")
  end
  
  def test_raises_on_simply_pay_type_through_manual_payment_creation
    i = invoices(:unpaid_invoice_1)
    assert_raises Sage::BusinessLogic::Exception::IncorrectDataException, "should not create simply manual payment" do
      post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'simply', :amount => 5, :created_by_id => users(:user_for_payments).id }
    end
  end

  def test_validation_message_on_blank_payment_type
    i = invoices(:unpaid_invoice_1)
    post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => '', :amount => 1.to_s, :created_by_id => users(:user_for_payments).id }
    assert_response :success
    assert @response.body.include?("Pay type is not included in the list")
  end

  def test_raises_on_simply_pay_type_through_manual_payment_update
    assert_raises Sage::BusinessLogic::Exception::IncorrectDataException, "should not create simply manual payment" do
        put :update, :id => payments(:full_payment_for_fully_paid_invoice).id, :payment => {
          :amount => 5, :pay_type => 'simply'}
    end
  end
  # weak
  def test_should_remove_commas_and_spaces_from_amount_when_creating
    post :create, :payment => {
      :customer_id => customers(:customer_for_payments).id,
      :invoice_id => invoices(:unpaid_invoice_1).id,
      :pay_type => 'cash',
      :amount => "1,0",
      :created_by_id => users(:user_for_payments).id }

    i = Invoice.find(invoices(:unpaid_invoice_1))
    assert_equal 10.0, i.paid_amount
  end
    
  def test_should_remove_commas_and_spaces_from_amount_when_updating
    put :update, :id => 10, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => "1 0", :created_by_id => 6 }
    i = Invoice.find(75)
    assert_equal 10.0, i.paid_amount
  end

  def test_mobile_version_view_edit
    get :edit, :id => 10, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end
  
  def test_mobile_version_on_invalid_submit_new
    i = invoices(:unpaid_invoice_1)
    get :edit, :id => 10, :mobile => 'true'
    post :create, :payment => { :invoice_id => i.id, :customer_id => 25, :pay_type => 'cash', :amount => 0, :created_by_id => users(:user_for_payments).id }
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("must be greater")
  end

  def test_mobile_version_on_invalid_submit_edit

    get :edit, :id => 10, :mobile => 'true'
    put :update, :id => 10, :payment => { :customer_id => 25, :pay_type => 'cash', :amount => 0, :created_by_id => 6 }
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("must be greater")
  end
end

