require File.dirname(__FILE__) + '/../test_helper'

class FeedbackMailerTest < ActionMailer::TestCase
  tests FeedbackMailer
  def test_feedback
    @user_email = "test@test.com"
    @user_msg = "hello, this is a comment I have"
    @user_name = "Bob"
    response = FeedbackMailer.create_feedback(@user_msg, @user_email, @user_name)
    deny response.nil?
  end

  def test_feedback_response
    @user_email = "test@test.com"
    @user_msg = "hello, this is a comment I have"
    @user_name = "Bob"
    @response_text = "asdf"
    response = FeedbackMailer.create_feedback_response(@user_name, @user_email, @response_text, @user_msg)
    deny response.nil?
  end

end
