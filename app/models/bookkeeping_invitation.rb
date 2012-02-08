class BookkeepingInvitation < Invitation

  def setup
    #TODO: Need a way to become a bookkeeper.
    # For now, user becomes a bookkeeper by accepting an invitation.
    #raise StandardError, "invitee is not a bookkeeper" if invitee.bookkeeper.nil?
    if invitee.bookkeeper.nil?
      invitee.create_bookkeeper 
      invitee.save!
    end
    invitee.bookkeeper.keep_books_for!(invitor.biller, self)
  end
  
  def self.create_with_bookkeeper_id(bookkeeper_id, invitor)  
    
    if bookkeeper_id
      bookkeeper = Bookkeeper.find(bookkeeper_id)
      invitee = bookkeeper.user
    else
      invitee = nil
    end

    bookkeeping_invitation = BookkeepingInvitation.create({
      :invitor => invitor,
      :invitee => invitee
    })
    
  end
  
  def teardown
    return if invitee.bookkeeper.nil?
    invitee.bookkeeper.stop_keeping_books_for!(invitor.biller)
  end

  # i18n ?
  def short_description
    _("Bookkeeping")
  end

  # i18n ?
  def long_description
    short_description
  end
end
