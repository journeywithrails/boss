require File.dirname(__FILE__) + '/../test_helper'

class BookkeepingInvitationMailerTest < ActionMailer::TestCase
  tests BookkeepingInvitationMailer
  CHARSET = "utf-8"
  
  fixtures :users

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
    
    @invitation = Invitation.create(:invitor => users(:basic_user))
    @delivery = Delivery.create(:deliverable => @invitation, :recipients => 'michael@10.152.17.65', :mail_options => {})
  end
  
  def test_send
    #@expected.subject = 'BookkeepingInvitationMailer#send'
    @expected.body    = read_fixture('send')
    @expected.date    = Time.now

    @invitation.expects(:create_access_key).returns('12345')
    response = BookkeepingInvitationMailer.create_send_invitation(@delivery, @expected.date)
    #assert_equal @expected.subject, response.subject
    assert_match 'access/12345', response.body
  end

  def test_should_setup_options_for_nil_invitee
    delivery = OpenStruct.new
    invitation = mock()
    user = mock()
    user.stubs(:name).returns('bob')
    # profile = mock()
    delivery.expects(:deliverable).returns(invitation)
    invitation.expects(:invitee).at_least(1).returns(nil)
    invitation.expects(:invitor).returns(user)
    # user.expects(:profile).returns(profile)
    # profile.expects(:company_name).returns('bob')
    options = BookkeepingInvitationMailer.options_for_send_invitation(delivery)
    assert options.is_a?(Hash)
    assert_equal('bob', options[:name])
    assert options[:show_recipients]
    assert_equal('bob would like to share their invoice data.', delivery.subject)
  end

  def test_should_setup_options_for_non_nil_invitee
    delivery = OpenStruct.new
    invitation = mock()
    user = mock()
    invitee = mock()
    invitee.stubs(:email).returns('invitee@test.com')
    user.stubs(:name).returns('bob')
    # profile = mock()
    delivery.expects(:deliverable).returns(invitation)
    invitation.expects(:invitee).at_least(1).returns(invitee)
    invitation.expects(:invitor).returns(user)
    # user.expects(:profile).returns(profile)
    # profile.expects(:company_name).returns('bob')
    options = BookkeepingInvitationMailer.options_for_send_invitation(delivery)
    assert options.is_a?(Hash)
    assert_equal('bob', options[:name])
    assert !options[:show_recipients]
    assert_equal('bob would like to share their invoice data.', delivery.subject)
  end

end
