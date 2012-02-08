require File.dirname(__FILE__) + '/../test_helper'

class DeliveriesControllerTester < DeliveriesController
  def request_nothing
    render :nothing => true
  end
end

class InvoiceMailerTest < Test::Unit::TestCase
  fixtures :configurable_settings
  fixtures :invoices
  
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @invoice = Invoice.create(:created_by_id => users(:basic_user).id)    
    @delivery = Delivery.create(:deliverable => @invoice, :recipients => 'michael@10.152.17.65',
                                :mail_options => {}, :created_by_id => users(:basic_user).id)
  end

  def test_send
    ak = @invoice.access_keys.create
    @invoice.expects(:create_access_key).returns(ak.key)
    email = InvoiceMailer.create_send(@delivery, nil, Time.now)
    assert_equal 'New invoice from basic_user_profile_name', email.subject
    assert_equal(["basic_user@billingboss.com"], email.reply_to)
    email.parts.each do |part|
      assert_match "access/#{ak.key}", part.body
    end
  end

  def test_send_with_pdf
    @controller = DeliveriesControllerTester.new
    allow_render
    @delivery.mail_options[:attach_pdf] = true
    email = InvoiceMailer.create_send(@delivery, @controller, Time.now)
  end

  def test_long_recipient_list
    @controller = DeliveriesControllerTester.new
    @send_invoice = invoices(:sent_invoice)
    @delivery = Delivery.create(:deliverable => @send_invoice, :recipients => 'michael@test.com',
                                :mail_options => {}, :created_by_id => users(:basic_user).id)

    @delivery.recipients = '1 012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234 <richard.zhou@sage.com>'

    email = InvoiceMailer.create_send(@delivery, @controller, Time.now)
    
    #puts email.encoded
    InvoiceMailer.deliver(email)
    
  end

  private

    def allow_render
      @request    = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      login_as :basic_user
      # RADAR: very obscure symptoms if this get has an exception (for example in filters)
      get :request_nothing
      @controller.instance_variable_set('@performed_render', nil)
    end

    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/invoice_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
