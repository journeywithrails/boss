class InvitationsController < ApplicationController

  prepend_before_filter CASClient::Frameworks::Rails::Filter, :except => [:display_invitation]
  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => [:display_invitation]

  def index
    @invitations = current_user.invitations

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @requests }
    end
  end

  def display_invitation
    # set signup_service_url, which is used by the signup_link helpers to override the default service url, which is profiles
    @signup_service_url = current_action_service_url(:force_login => '1')
    if_valid_access_key do |ak|
      if not logged_in?
        #self.store_location(accept_invitation_path(:id => params[:id]))
        self.store_location()
      end
      @invitation = Invitation.find(ak.keyable_id)
      #load the company's profile for displaying company address, logo etc...

      @profile = Profile.new(@invitation.invitor)
      @key = ak.key

      respond_to do |format|
        format.html do
          if @invitation.withdrawn?
            @error_message = @invitation.
            render :template => "#{controller_name}/error", :layout => external_layout
            return
          end
          if logged_in?
            if current_user.id == @invitation.created_by_id
              session[:return_to] = nil
              @error_message = invite_self_error_message
              render :template => "#{controller_name}/error", :layout => external_layout
            elsif (current_user.id == @invitation.invitee_id) && (@invitation.confirmed?)
              render :template => "#{controller_name}/accepted"
            else
              render :template => "#{controller_name}/display_invitation_logged_in"
            end
          else
            @recipient = @invitation.recipient
            user = User.find_by_email(@recipient)
            if user.nil?
              # added skip_header for functionals to work
              @skip_header = true
              render :template => "#{controller_name}/invitation_new_user", :layout => external_layout
            else
              render :template => "#{controller_name}/invitation_existing_user", :layout => external_layout
            end
          end
        end
        format.xml  { render :xml => 'invitation' }
      end
    end
  end

  # Thanks for accepting the invite.
  def accept
    if_valid_access_key do |ak|
      @invitation = Invitation.find(ak.keyable_id)
      RAILS_DEFAULT_LOGGER.debug("@invitation: #{@invitation.inspect}")
      if @invitation.accept_invitation_for(current_user)
        respond_to do |format|
          format.html { 
            set_view_for_invitation
            redirect_to :controller => controller_name, :action => 'show', :id => @invitation.to_param
            }
          format.xml  { render :xml => 'accepted' }
        end
      else
        render_failure # Error message already added
      end
    end
    
  end
  
  def decline
    if_valid_access_key do |ak|
      @invitation = Invitation.find(ak.keyable_id)
      if @invitation.decline_invitation_for(current_user)
        respond_to do |format|
          format.html {
            redirect_to :controller => controller_name, :action => 'show', :id => @invitation.to_param
          }
          format.xml  { render :xml => 'declined' }
        end
      else
        render_failure # Error message already added
      end
    end
  end

  def show
    @invitation = Invitation.find(params[:id])
    RAILS_DEFAULT_LOGGER.debug("@invitation.status: #{@invitation.status.inspect}")
    case true
    when @invitation.accepted?, @invitation.confirmed?
      render :template => "#{controller_name}/accepted"
    when @invitation.declined?
      render :template => "#{controller_name}/declined"
    else
      @error_message = @invitation.status_explanation
      render :template => "#{controller_name}/error", :layout => external_layout #why external layout?
    end      
  end
  
  protected
  # override in subclass to set the current view of the user upon accepting invitation
  def set_view_for_invitation
  end
  
  def invite_self_error_message
    _("You cannot invite yourself. Please %{link} first and then follow the invitation link again.") % {:link => "<a href='/logout'>_('log out')</a>"}
  end

  def if_valid_access_key
    ak = AccessKey.find_by_key(params[:id])
    if ak.nil?
      render(:template=>"access/not_found", :status => :not_found)
    else
      if ak.use?
        yield(ak)
      else
        render_failure
      end
    end
  end
  
  def render_failure (message = nil)
    if not message.nil? and not @invitation.nil?
      @message = message
      @invitation.errors.add_to_base(message)
    end
    respond_to do |format|
      format.html { render :template => "#{controller_name}/failed"}
      format.xml  { render :xml => 'failed', :status => :unprocessable_entity }
    end
  end

  # this is used by cas filter to override gateway
  def force_login?
    !!params[:force_login]
  end
end
