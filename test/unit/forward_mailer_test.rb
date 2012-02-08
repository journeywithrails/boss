require File.dirname(__FILE__) + '/../test_helper'

class ForwardMailerTest < Test::Unit::TestCase
  fixtures :configurable_settings
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"
  
  include ActionMailer::Quoting
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []    
  end
  
  def test_forward_reply
    invoice = Invoice.create(:created_by_id => users(:basic_user).id)
    delivery = Delivery.create(:deliverable => invoice, :recipients => 'john@smith.com',
                                :mail_options => {}, :created_by_id => users(:basic_user).id)
    delivery.deliverable_id = '1'
    bounce = Bounce.create!(:user => nil, :delivery => delivery, :body => "bounced mail body here")
    response = BounceMailer.create_forward_bounce("john@smith.com", bounce)
    assert_match /Bounced Mail/, response.subject
    assert_match /We were unable to deliver invoice/, response.body
  end
  
end
