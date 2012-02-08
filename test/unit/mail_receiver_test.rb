require File.dirname(__FILE__) + '/../test_helper'

class MailReceiverTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  fixtures :configurable_settings
  CHARSET = "utf-8"
  
  include ActionMailer::Quoting
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    @email = TMail::Mail.new
  end
  
  def test_should_pass_bounced_mail_to_bounce_model
    @email.body = read_fixture('bounced_mail')
    response = MailReceiver.create_receive(@email)
    
    assert_not_nil response
  end
  
  def test_should_pass_replied_mail_to_forward_model
    @email.body = read_fixture('replied_mail')
    response = MailReceiver.create_receive(@email)
    
    assert_not_nil response
  end
  
  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/mail_receiver/#{action}")
    end
end
