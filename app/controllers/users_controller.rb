class UsersController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter, :except => [:signup]


  include ApiTokenSupport

  layout :external_layout

  def thankyou
    @user = self.current_user
    if api_token?
      api_token.set_current_user(current_user)
      render :action => 'simply/thankyou', :layout => :internal_layout
    else
      redirect_to first_profile_edit_url
    end
  end
  
  def signup
    logout_current_user
    ProcessSignupFilter.filter(self) # we need to recall ProcessSignupFilter, because logout_current_user clears session
    redirect_to signup_url
  end
  
  def communications
    if api_token?
      render :action => 'simply/communications'
    else
      render
    end
  end
  
  #record the fact that Net promoter survey has been clicked so that we do not promot the user again
  def survey_clicked
     @user = self.current_user    
     @profile = @user.profile
     @profile.survey_clicked = true
     @profile.survey_clicked_date = DateTime.now
     @profile.save
     render :text=>""    
  end
  
  protected

def confirm_password_for_xml
    if request.format == Mime::XML
      @user.password_confirmation = params[:user][:password]
    end
  end

  def path_to_redirect
    if api_token?
      # clear and discard the redirect location (would eventually be to the
      # deliveries controller) in favour of the thank you version of things
      clear_redirect_location('')
      thankyou_user_path(current_user)
    elsif session[:login_from] == "rac"
      clear_redirect_location('/rac_contest/tell_a_client') 
    else
      clear_redirect_location('/tabs/biller')
    end
  end
  
end
