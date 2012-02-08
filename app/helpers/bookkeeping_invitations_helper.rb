module BookkeepingInvitationsHelper
  def invitor_name
    @invitation.invitor.profile.company_name.blank? ? @invitation.invitor.sage_username : @invitation.invitor.profile.company_name
  end

  def api_token?
    false
  end
end
