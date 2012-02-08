require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/feedback_controller'

class Admin::FeedbackControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :roles
  fixtures :roles_users
  fixtures :feedbacks
  def setup
    @controller = Admin::FeedbackController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_requires_login
    logout
    get :index
    assert_redirected_to "access/denied"
  end

  def test_disallows_non_admin
    login_as :basic_user
    get :index
    assert_redirected_to 'access/denied'
  end
  
  def test_disallows_admin_without_feedback_admin_role
    login_as :peon_admin_user
    get :index
    assert_redirected_to 'access/denied'
  end
  
  def test_allows_master_admin
    login_as :master_admin_user
    get :index
    assert_response :success

  end
  
  def test_allows_feedback_admin
    login_as :feedback_admin_user
    get :index
    assert_response :success
  end
  
  def test_filters
    login_as :feedback_admin_user
    get :index

    assert_select "td#feedback_item_1_id", 0  
    
    submit_filter(1,1,1,1,1,1,"LF")
    assert_select "span#total_matching_feedbacks[value=9]"
    assert_select "td#feedback_item_1_id"    
    assert_select "td#feedback_item_2_id"
    assert_select "td#feedback_item_3_id"
    assert_select "td#feedback_item_4_id"    
    assert_select "td#feedback_item_5_id"
    assert_select "td#feedback_item_6_id"
    assert_select "td#feedback_item_7_id" 
    assert_select "td#feedback_item_8_id"
    assert_select "td#feedback_item_9_id"
    
    submit_filter(1,0,0,1,0,0,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_1_id"    

    submit_filter(0,1,0,1,0,0,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_2_id"  

    submit_filter(0,0,1,1,0,0,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_3_id"

    submit_filter(1,0,0,0,1,0,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_4_id"

    submit_filter(0,1,0,0,1,0,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_5_id"

    submit_filter(0,0,1,0,1,0,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_6_id"

    submit_filter(1,0,0,0,0,1,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_7_id"

    submit_filter(0,1,0,0,0,1,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_8_id"  

    submit_filter(0,0,1,0,0,1,"LF")
    assert_select "span#total_matching_feedbacks[value=1]"
    assert_select "td#feedback_item_9_id"
  
  end
  
  def test_filter_by_order
    f = Feedback.new
    f.text_to_send = "test text"
    f.user_name = "test name"
    f.user_email = "test@email.com"
    f.save!

    login_as :feedback_admin_user
    get :index
    submit_filter(1,1,1,1,1,1,"LF")
    assert_select("table#feedback_item_#{f.id}[number=1]") 

    submit_filter(1,1,1,1,1,1,"EF")
    assert_select("table#feedback_item_#{f.id}[number=10]")     
  end
  
  def test_deleting_feedback
    login_as :feedback_admin_user
    get :index
    assert_difference('Feedback.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to '/admin/feedback'
  end
  
  def test_editing_feedback_with_no_email
    login_as :feedback_admin_user
    get :edit, :id => 1
    assert_response :success
    assert_select "input#feedback_email_reply", 0
    assert_select "option[selected=selected][value=Open]"     
    put :update, :id => 1, :feedback => {:id => 1, :status => "Closed"}
    assert_response :redirect
    f = Feedback.find(1)
    assert_equal "Closed", f.response_status
  end
  
  def test_editing_feedback_with_email
    f = Feedback.new
    f.text_to_send = "test text"
    f.user_name = "test name"
    f.user_email = "test@email.com"
    f.save!
    
    login_as :feedback_admin_user
    get :edit, :id => f.id
    assert_response :success
    assert_select "input#feedback_email_reply"    
  end
  
  def test_owner_set_to_nil_if_rejected_by_owner
    login_as :feedback_admin_user
    get :edit, :id => 1
    put :update, :id => 1, :feedback => {:id => 1, :claim => "No"}    
    assert_response :redirect
    f = Feedback.find(1)
    assert_equal "0", f.owned_by.to_s    
  end
  
  def test_owner_not_set_to_nil_if_rejected_by_non_owner
    login_as :feedback_admin_user
    get :edit, :id => 7
    put :update, :id => 7, :feedback => {:id => 7, :claim => "No"}    
    assert_response :redirect
    f = Feedback.find(7)
    assert_equal "17", f.owned_by.to_s      
  end
  
  protected
  def submit_filter(open, in_review, closed, me, nobody, others, order)
    if (order == "ef") or (order == "EF")
      order_by = "Earliest to latest"
    else
      order_by = "Latest to earliest"      
    end
    post :filter, :filters => {
      :f_open => open.to_s,
      :f_in_review => in_review.to_s, 
      :f_closed => closed.to_s, 
      :f_me => me.to_s,
      :f_nobody => nobody.to_s, 
      :f_others => others.to_s, 
      :order_by => order_by
    }
  end
  
  def test_list
    get :list
    assert_response :success
  end
  
  def test_show
    get :show
    assert_response :success
  end
  
  
end