# This controller handles the login/logout function of the site.  

class SessionController < ApplicationController
  include ApiTokenSupport

  layout :external_layout
  prepend_before_filter CASClient::Frameworks::Rails::Filter, :except => [:redirect, :test_login, :test_logout, :test_gateway, :test_first_login, :destroy, :current_session]
  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => [:destroy]
  prepend_before_filter :logout_current_user, :only => [:new]


  def new
    RAILS_DEFAULT_LOGGER.debug("sessioncontroller.new")    
    render_start_page    
  end

#if in test mode, enable log in without accessing the UI. For acceptance test
if ENV['RAILS_ENV'] == 'test'

  include CasTestHelper
  public
  def test_login
    user = User.find(params[:id])  
    self.current_user = user
    stub_cas_logged_in(user)    
    session[:sage_user] = user.sage_username
    session[:user] = user.id 
    render :text => user.sage_username + " logged in test mode"
  end
  
  def test_first_login
    stub_cas_first_login(params[:pending_sage_user], params[:pending_sage_user_email])
    render :text => "first login prepared for #{params[:pending_sage_user]}"
  end
  
  def test_gateway
    RAILS_DEFAULT_LOGGER.debug("stubbing gateway!!!!")    
    current_user = nil
    reset_session
    stub_cas_logged_out
    render :text => "logged out with stubbed cas gateway"
  end
  
  def test_logout
    current_user = nil
    reset_session
    unstub_cas
    render :text => "logged out & cas unstubbed"
  end
  
  def current_session
    out = {}
    if params[:k]
      params[:k].each do |key|
        out[key] = session[key.to_sym]
      end
    end
    render :text => out.to_yaml
  end
end


  
  def logged_on
    if api_token?
      render :action => 'simply/logged_on', :layout => :internal_layout
    else
      render
    end
  end

  def destroy
    CASClient::Frameworks::Rails::Filter.logout(self, home_url)
  end
  
  def redirect
    
  end
  
  private 
  
  def render_start_page
    RAILS_DEFAULT_LOGGER.debug("render_start_page")    
    if logged_in?
      RAILS_DEFAULT_LOGGER.debug("render_start_page: logged_in")
      if params[:locale].blank?
        change_language!(current_user.language)
      else
        if available_language?(params[:locale])
          current_user.update_language!(params[:locale])
        end
      end
      redirect_path = self.path_to_redirect    
    else
      redirect_path = clear_redirect_location('/')
    end
    RAILS_DEFAULT_LOGGER.debug("render_start_page: redirect_path: #{redirect_path.inspect}")
    
    redirect_to_path_dropping_ssl redirect_path
  end
  
  protected

  def path_to_redirect
    RAILS_DEFAULT_LOGGER.debug("path_to_redirect")
    
    if session[:login_from] == "rac"
      clear_redirect_location('/rac_contest/tell_a_client') 
    elsif api_token?
      RAILS_DEFAULT_LOGGER.debug("path_to_redirect: api_token true")
      clear_redirect_location("/session/logged_on")
    else
      session[:login_from] = nil
      clear_redirect_location(@template.user_home_path)
    end
  end
end
