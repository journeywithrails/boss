require File.dirname(__FILE__) + '/../test_helper'

class BookkeepingInvitationTest < ActiveSupport::TestCase
  fixtures :users, :invitations, :bookkeepers
  
  def test_should_accept_invitation_for_bookkeeper
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    u = User.find(users(:bookkeeper_user))
    assert u.bookkeeper
    assert i.invitor.biller
    
    assert_difference('BookkeepingContract.count', 1) do
      assert_difference('Role.count', 1) do
        assert i.accept_invitation_for(u)
      end
    end
  end
  
  def test_should_decline_invitation_for_bookkeeper
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    u = User.find(users(:bookkeeper_user))
    assert u.bookkeeper
    assert i.invitor.biller
    
    assert_no_difference('BookkeepingContract.count') do
      assert_no_difference('Role.count') do
        assert i.decline_invitation_for(u)
      end
    end
  end
  
  def test_should_neither_accept_nor_deny_invitation_after_invitation_accepted
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    u = User.find(users(:bookkeeper_user))
    assert u.bookkeeper
    assert i.accept_invitation_for(u)

    deny i.accept_invitation_for(u)
    deny i.decline_invitation_for(u)
  end
  
#  def test_should_reject_response_from_non_bookkeeper
#    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
#    u = User.find(users(:heavy_user))
#    
#    deny i.accept_invitation_for(u)
#    deny i.decline_invitation_for(u)
#  end
  def test_should_become_bookkeeper_when_accepting_invitation
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    u = User.find(users(:heavy_user))
    deny u.bookkeeper
    
    assert i.accept_invitation_for(u)
    u.reload
    assert u.bookkeeper
  end
  
  def test_should_not_become_bookkeeper_when_accepting_previously_declined_invitation
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    u = User.find(users(:heavy_user))
    deny u.bookkeeper
    
    assert i.decline_invitation_for(u)
    deny u.bookkeeper
    
    deny i.accept_invitation_for(u)
    u.reload
    deny u.bookkeeper
  end
  
  def test_should_rescind_invitation
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    u = User.find(users(:bookkeeper_user))
    
    assert_difference('BookkeepingContract.count', 1) do
      assert_difference('Role.count', 1) do
        assert i.accept_invitation_for(u)
      end
    end

    assert_difference('BookkeepingContract.count', -1) do
      assert_difference('Role.count', -1) do
        i.rescind!
      end
    end

  end

  def test_should_describe_what_it_is
    i = Invitation.find(invitations(:invitation_for_unknown_bookkeeper))
    assert_match(/Bookkeeping/, i.short_description)
    assert_match(/Bookkeeping/, i.long_description)
  end
  
  def test_should_create_with_bookkeeper_id
    bookkeeper = Bookkeeper.find(bookkeepers(:first_bookkeeper))    
    invitor = User.find(users(:basic_user))
    assert_difference('BookkeepingInvitation.count') do
      BookkeepingInvitation.create_with_bookkeeper_id(bookkeeper.id, invitor)
    end
    
    assert_difference('BookkeepingInvitation.count') do
      BookkeepingInvitation.create_with_bookkeeper_id(nil, invitor)
    end    
    
  end
  
end
