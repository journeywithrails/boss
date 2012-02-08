require File.dirname(__FILE__) + '/../test_helper'
require 'feedback_controller'

class FeedbackControllerTest < ActionController::TestCase

 def setup
    @controller = FeedbackController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []    
    
    login_as :basic_user
  end
  
  # Replace this with your real tests.
  def test_feedback_sent
    assert_difference ('Feedback.count') do
    num_deliveries = ActionMailer::Base.deliveries.size
      post :create, :feedback => {:text_to_send => 'this is good!', :user_name=>"bob the man", :user_email=>"bob@bob.com"}
      if ::AppConfig.mail_feedback
        assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size
      end
    end
  end
  
  def test_blank_feedback
    assert_no_difference ('Feedback.count') do
    num_deliveries = ActionMailer::Base.deliveries.size
      post :create, :feedback => {:text_to_send => '', :user_name=>"bob the man", :user_email=>"bob@bob.com"}
      if ::AppConfig.mail_feedback
        assert_equal num_deliveries, ActionMailer::Base.deliveries.size
      end
    end    
  end
  
  def test_new
    get :new
    assert_response :success
  end
  
  def test_index
    get :index
    assert_response :success
  end
  
  def test_get_create
    get :create
    assert_response :redirect
  end
  
  
end
