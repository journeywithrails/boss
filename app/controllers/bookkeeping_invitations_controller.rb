class BookkeepingInvitationsController < InvitationsController

  def new

    bookkeeping_invitation = BookkeepingInvitation.create_with_bookkeeper_id(params[:bookkeeper_id], current_user)
    invitee = bookkeeping_invitation.invitee
    recipients = (invitee.nil? ?  nil : invitee.email)
    
    @delivery = current_user.deliveries.build({
      :deliverable => bookkeeping_invitation,
      :mail_name => 'send_invitation',
      :recipients => recipients 
    })
    
    @delivery.setup_mail_options

    respond_to do |format|
      format.html do
        if request.xhr?
          @show_controls = false
          render :template => 'deliveries/new', :layout => 'dialog' 
        else
          @show_controls = true
          render :template => 'deliveries/new'
        end
      end
      format.xml  { render :xml => @delivery }
    end
  end
  
  
  protected
  def invite_self_error_message
    _("You cannot add yourself as a bookkeeper. Please %{link} first and then follow the invitation link again.") % {:link => "<a href='/logout'>_('log out')</a>"}
  end
  
  def set_view_for_invitation
    current_user.profile.current_view = :bookkeeper
  end
  
end
