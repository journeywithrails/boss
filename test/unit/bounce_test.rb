require File.dirname(__FILE__) + '/../test_helper'

class BounceTest < ActiveSupport::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    @email = TMail::Mail.new
  end
  
  def test_should_not_proccess_if_mail_is_a_regular_mail
    @email.body = read_fixture('regular_mail')
    response = Bounce.create_for(@email.to_s)    
    
    assert_nil response
  end
  
  def test_should_process_bounced_mail
    @email.body = read_fixture('bounced_mail')
    response = Bounce.create_for(@email.to_s)    
    
    assert_not_nil response
  end
  
  def test_should_create_new_bounce_record
    count = Bounce.count
    @email.body = read_fixture('bounced_mail')
    response = Bounce.create_for(@email.to_s)
    
    assert_equal Bounce.count, count+1
  end
  
  def test_bounced_delivery_status_should_be_changed
    @email.body = read_fixture('bounced_mail')
    response = Bounce.create_for(@email.to_s)
    
    assert_equal "failure", Delivery.find(1).status
  end
  
  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/mail_receiver/#{action}")
    end
end
