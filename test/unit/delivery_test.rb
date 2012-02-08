require File.dirname(__FILE__) + '/../test_helper'

class DeliveryTest < ActiveSupport::TestCase
  class TestDeliverable; end
  class TestDeliverableMailer; end

  fixtures :users, :invoices
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @delivery = Delivery.create
    @delivery.recipients = 'test@example.com'
    @test_object = TestDeliverable.new
    TestDeliverable.any_instance.stubs(:new_record?).returns(true)
    TestDeliverable.stubs(:base_class).returns(TestDeliverable)
    @test_object.stubs(:id).returns(1)
    @test_object.stubs(:save).returns(true)
    @delivery.deliverable = @test_object
  end
  
  # Replace this with your real tests.
  def test_mail_options_empty_hash_by_default
    assert_equal Hash.new, @delivery.mail_options
  end
  
  def test_deliver_mail
    @delivery.mail_name = 'test'
    @delivery.save
    @test_object.expects(:deliver!).returns(true)
    TestDeliverableMailer.expects(:deliver_test).returns(OpenStruct.new({:message_id => '12345'}))
    @delivery.deliver!
    
    assert_equal 'sent', @delivery.status
  end

  def test_deliver_mail_copy   
    @delivery.mail_name = 'test'
    @delivery.mail_options[:email_copy] = "on"
    @delivery.save
    controller = DeliveriesController.new
    controller.stubs(:current_user).returns(@user = users(:complete_user))
    @test_object.expects(:deliver!).returns(true)
    TestDeliverableMailer.expects(:deliver_test).times(2).returns(OpenStruct.new({:message_id => '12345'}))
    @delivery.deliver! controller
    assert_equal 'sent', @delivery.status
  end
  
  def test_deliver_mail_with_deliverable_deliver_failure_sets_status_to_error
    @delivery.mail_name = 'test'
    @delivery.save
    @test_object.expects(:deliver!).returns(false)
    TestDeliverableMailer.expects(:deliver_test).never
    ok = @delivery.deliver!
    assert !ok
    assert 'error', @delivery.status
  end

  def test_exception_in_delivery_sets_state_to_error
    @delivery.mail_name = 'test'
    @delivery.save
    @test_object.expects(:deliver!).returns(true)
    TestDeliverableMailer.expects(:deliver_test).raises(StandardError)
    @delivery.deliver!
    assert 'error', @delivery.status
  end

  def test_should_get_mailer_klass_from_deliverable
    assert_equal @delivery.mailer_klass, TestDeliverableMailer
  end

  def test_should_get_mail_method_name
    @delivery.mail_name = 'test'
    assert_equal @delivery.deliver_mail_method, :deliver_test
  end

  def test_should_return_deliverable_description
    delivery = Delivery.create
    delivery.recipients = 'test@example.com'
    assert_equal '', delivery.deliverable_description
    delivery.deliverable = @test_object
    delivery.save
    assert_equal 'DeliveryTest::TestDeliverable: 1', delivery.deliverable_description
    @test_object.expects(:description).returns('bob is cool')
    assert_equal 'bob is cool', delivery.deliverable_description
  end

  # test for typos. And for 100%.
  def test_should_return_request_params
    assert @delivery.request_params
    assert @delivery.request_params[:delivery]
    assert_equal @delivery.mail_name, @delivery.request_params[:delivery][:mail_name]
    assert_equal @delivery.deliverable_type, @delivery.request_params[:delivery][:deliverable_type]
    assert_equal @delivery.deliverable_id, @delivery.request_params[:delivery][:deliverable_id]
  end

  def test_delivery_requires_list_of_recipients
    @delivery.recipients = ''
    assert !@delivery.valid?

    @delivery.recipients = 'howdy'
    assert !@delivery.valid?

    @delivery.recipients = 'test@example.com'
    assert @delivery.valid?

    @delivery.recipients = 'test@example.com'
    assert @delivery.valid?


  end


  def test_should_allow_valid_email_addresses
    ['valid@example.com',
     'valid@test.example.com',
     'valid+valid123@test.example.com',
     'valid_valid123@test.example.com',
     'valid-valid+123@test.example.co.uk',
     'valid-valid+1.23@test.example.com.au',
     'valid@example.co.uk',
     'v@example.com',
     'valid@example.ca',
     'valid123.456@example.org',
    'valid123.456@adomain.gov',
     'valid123.456@example.travel',
     'valid123.456@example.museum',
     'valid123.456@example.asia',
     'vtest@mydomain.edu',
     'vtest@mydomain.com.cn',
     'test@example.mobi',
     'valid@example.info',
     'Some Guy <someguy@example.com>, mary@example.com'
     ].each do |email|
      @delivery.recipients = email
      assert @delivery.valid?, "#{email} was incorrectly identified as invalid"
    end
  end

  def test_should_not_allow_invalid_email_addresses
    ['_invalid@example.com',
     'invalid@example-com',
     'invalid_@example.com',
     'invalid-@example.com',
     '.invalid@example.com',
     'invalid.@example.com',
     'invalid@example.com.',
     'invalid@example.com_',
     'invalid@example.com-',
     'invalid-example.com',
     'invalid@example.b#r.com',
     'invalid@example.c',
     'invali d@example.com',
     'invalidexample.com',
     'invalid@e.',
     'rob@.c',
     'invalid@example.'].each do |email|
      @delivery.recipients = email
      assert !@delivery.valid?, "#{email} was incorrectly identified as valid"
    end
  end

  def test_should_use_deliverable_default_recipients
    @test_object.expects(:default_recipients).returns('some_value')
    delivery = Delivery.new(:deliverable => @test_object)
    assert_equal 'some_value', delivery.recipients
  end

  def test_should_not_allow_recipient_to_be_the_same_as_invitor
    @invitation = Invitation.create(:invitor => users(:basic_user))
    @delivery = Delivery.create(:deliverable => @invitation, :recipients => 'basic_user@billingboss.com', :mail_options => {})
    assert !@delivery.valid?, "basic_user@billingboss.com cannot send an invitation to himself"
  end

  def test_should_setup_mail_options_from_mailer
    @delivery.mail_name = 'test'
    assert @delivery.setup_mail_options.is_a?(Hash), "if mailer has no setup method, should be an empty hash"
    assert @delivery.setup_mail_options.empty?, "if mailer has no setup method, should be an empty hash"

    @delivery.mail_options = {:bob => 'bob'}
    TestDeliverableMailer.expects(:options_for_test).returns({:test => 'ok'})
    options = @delivery.setup_mail_options

    assert options.is_a?(Hash), "return should be a hash"
    assert !options.empty?, "return should not be empty"
    assert_equal('ok', options[:test])

    assert @delivery.mail_options.is_a?(Hash), "options should be merged into mail_options attribute"
    assert !@delivery.mail_options.empty?
    assert_equal('ok', @delivery.mail_options[:test])
    assert_equal('bob', @delivery.mail_options[:bob])


  end

  def should_create_valid_reply_to
    u = users(:basic_user)
    profile = OpenStruct.new({:company_name => "This, <won't> work as is"})
    u.stubs(:profile).returns(profile)
    d = u.deliveries.build
    assert_match /<#{users(:basic_user).email}>/, d.reply_to
    deny d.reply_to.include?(',')
    deny d.reply_to.include?('<w')
  end
end
