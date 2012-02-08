module InvitationsHelper
  
  def translated_status(status)
    case status
    when 'created'
      _('created')
    when 'sent'
      _('sent')
    when 'withdrawn'
      _('withdrawn')
    when 'declined'
      _('declined')      
    when 'accepted'
      _('accepted')
    when 'confirmed'
      _('confirmed')
    when 'rescinded'
      _('rescinded')
    when 'terminated'
      _('terminated')
    end
  end
  
end
