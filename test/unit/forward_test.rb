require File.dirname(__FILE__) + '/../test_helper'

class ForwardTest < ActiveSupport::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  fixtures :invoices
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    @email = TMail::Mail.new
    @email.body = read_fixture('replied_mail')
    
  end
  
  def test_should_process_replied_mail
    response = Forward.create_for(@email.to_s)
    
    assert_not_nil response
  end
  
  def test_should_forward_to_sender
    count = Activity.count
    @invoice = invoices(:resent_invoice)
    sender = "neil@neil.com"
    
    Forward.forward_to_sender(@invoice, sender, @email.to_s)
    
    assert_equal Activity.count, count+1
  end
  
  def test_should_locate_sender_from_email
    response = Forward.locate_sender(@email.to_s)
    
    assert_equal "helloworld@example.com", response
  end
  
  def test_should_locate_invoice_by_guid
    @invoice = invoices(:resent_invoice)
    
    invoice = Forward.locate_invoice_by_guid(@email.to_s)
    
    assert_equal invoice, @invoice
  end
  
  def test_should_extract_access_key
    response = Forward.extract_access_key(@email.to_s)
    
    assert_equal "d1f88a69c402437f991cd58d5918024b", response 
  end
  
  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/mail_receiver/#{action}")
    end
end
