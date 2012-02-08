require 'last_obelus/active_record/valid_for_attributes'

class ReferralController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter
  
  def index
    new
  end
  
  def accepted
    get_username
    render_with_a_layout("accepted", "external_main")    
    @contest_action = ""
  end
  
  def create
    get_username
    if request.post?

      @came_from_contest = params[:referral][:came_from_contest]
      @came_from_rac_contest = params[:referral][:came_from_rac_contest]
      @friend_invited = false
      @referrals = []
      @valid_referring_name, @valid_referring_email = true
      i = 1
      
      if ::AppConfig.referral_captcha 
        if !simple_captcha_valid?
          @bad_captcha = true
        end
      end
      
      i.upto(::AppConfig.referrals_size) do |i|
        
        r = Referral.new
        r.referring_email = params[:referral][:referrer_email]
        r.referring_name = params[:referral][:referrer_name]
        
        if User.valid_signup_type?(session[:signup_type])
          r.referring_type = session[:signup_type]
        else
          r.referring_type = User.DefaultSignupType
        end
        
        @referring_email = r.referring_email
        @referring_name = r.referring_name
        
        r.friend_email = params[:referral]["friend_email_#{i}"]
        r.friend_name = params[:referral]["friend_name_#{i}"]

        if !r.valid? and not blank_friend?(r)
          @error = true unless r.duplicate_email?
        end
        
        if !r.valid_for_attributes?(:referring_name)
          @valid_referring_name = false
        end
        
        if !r.valid_for_attributes?(:referring_email)
          @valid_referring_email = false
        end
        
        if blank_friend?(r)
          r = nil;
        else
          @friend_invited = true
        end  
        
        @referrals[i] = r
      end

      #if not @error, that means there are no synthax errors
      #there still may be duplication errors (thats why we
      #save each before checking if next one is valid
      #user does not need to be notified of duplication errors
      #just continue next one, since the first one will be sent
      if !@friend_invited
        @error = true
      end
      if !@error
        if !@bad_captcha
          @referrals.each do |r|
            if !r.blank? and r.valid?
              if !r.mail_quota_exceeded? and !r.already_accepted?
                r.save!
                url_base = request.host_with_port
                if session[:signup_type] and (session[:signup_type].downcase == "ssan")
                  @ssan = true
                end
                ReferralMailer.deliver_referral(r, url_base, @ssan)
                r.sent_at = DateTime.now
                r.save!
              end
            end
          end
          flash[:notice] = _("The invitations have been sent out!")
          if !@came_from_contest.blank?
            redirect_to :controller => "contest", :action => "tell_a_friend_accepted"
          elsif !@came_from_rac_contest.blank?
            redirect_to :controller => "rac_contest", :action => "tell_a_client_accepted"
          else
            redirect_to :action => :accepted
          end
        else
          flash[:warning] =  _("Invalid code entered. Please try again.")
          @error = true
          render_error
        end
      else
        if !@friend_invited
          flash[:warning] = _("You have not invited any friends. Please fill out at least one friend's e-mail.")
        else
          flash[:warning] = _("You must enter your name and e-mail, and a valid e-mail for each friend you invite. Invalid fields have been highlighted.")
        end
        render_error
      end

    end

    flash[:notice] = nil
  end

  def new
    get_username
    render_with_a_layout("new", "external_main")
  end

  protected

  def blank_friend?(r)
    if r.friend_name.blank? and r.friend_email.blank?
      return true
    else
      return false
    end
  end
  
  def get_username
    @username = current_user.sage_username if logged_in?    
  end
  
  def render_error
    if !@came_from_contest.blank?
      render :template => "contest/tell_a_friend", :layout => "contest"
    elsif !@came_from_rac_contest.blank?
      render :template => "rac_contest/tell_a_client", :layout => "contest"
    else
      new
    end
  end

end
