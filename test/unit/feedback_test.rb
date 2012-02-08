require File.dirname(__FILE__) + '/../test_helper'

class FeedbackTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_valid
    f = Feedback.new
    f.user_email = "asdf"
    deny f.valid?
    f.text_to_send = "asdf"
    assert f.valid?
    
  end
  
  def test_populate_fields
    f = Feedback.new
    f.populate_fields
    assert_equal "Open", f.response_status
    assert_equal "", f.user_email
    
    f.user_email = "test@test.com"
    f.populate_fields
    assert_equal "test@test.com", f.user_email
  end
end
