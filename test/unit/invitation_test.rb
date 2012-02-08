require File.dirname(__FILE__) + '/../test_helper'

class InvitationTest < ActiveSupport::TestCase

  fixtures :users, :invitations

  def test_invitation_should_be_sendable_if_valid
    invite_valid = Invitation.new
    invite_valid.expects(:valid?).returns(false)
    assert !invite_valid.sendable?
    
    invite_invalid = Invitation.new
    invite_invalid.expects(:valid?).returns(true)
    assert invite_invalid.sendable?
  end
  
  def test_ensure_invitee_when_invitee_is_nil
    i = Invitation.new
    u = User.find(:first)

    assert i.invitee.nil?
    assert i.ensure_invitee(u)
    assert_equal u, i.invitee
  end
  
  def test_ensure_invitee_when_invitee_is_already_user
    i = Invitation.new
    u = User.find(:first)
    i.invitee = u

    assert i.ensure_invitee(u)
    assert_equal u, i.invitee
  end

  def test_ensure_invitee_when_invitee_is_different_user
    i = Invitation.new
    u = User.find(users(:basic_user))
    u2 = User.find(users(:heavy_user))
    i.invitee = u

    deny i.ensure_invitee(u2)
    assert_equal u, i.invitee
  end

# covered in bookkeeping_invitation_test
#  def test_should_accept_invitation_for_invitee
#  end
#  
#  def test_should_decline_invitaiton_for_invitee
#  end
#  
#  def test_should_neither_accept_nor_deny_invitation_after_invitation_accepted
#  end

  def test_should_fail_when_invitee_is_different_user
    i = Invitation.find(invitations(:invitation_for_bookkeeper))
    u = User.find(users(:other_bookkeeper_user))
    deny i.accept_invitation_for(u)
  end
  
  def test_should_fail_inviting_yourself
    i = Invitation.find(invitations(:invitation_for_yourself))
    u = User.find(users(:wants_bookkeeper_user))
    deny i.accept_invitation_for(u)    
  end
  
  def test_should_fail_to_accept_unsent_invitation
    invitee = User.find(users(:basic_user))
    invitor = User.find(users(:heavy_user))
    i = invitor.invitations.create(:invitee => invitee)
    assert_equal 'created', i.status
    
    deny i.accept_invitation_for(invitee)
    assert_equal 'Failed to accept invitation.', i.errors.on_base
  end
  
  def test_should_fail_to_decline_declined_invitation
    i = Invitation.find(invitations(:invitation_for_bookkeeper))
    u = User.find(users(:bookkeeper_user))
    assert i.decline_invitation_for(u)
    deny i.decline_invitation_for(u)
  end
  
  def test_recipient
    i = Invitation.find(invitations(:invitation_for_bookkeeper))
    r = i.recipient
    assert_equal "bookkeeper_user@billingboss.com", r
  end
  
end
