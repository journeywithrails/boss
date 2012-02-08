class UserGatewaysController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter
  include ApiTokenSupport
  
  before_filter :api_token_required, :only => [:switch_to_sps]
  before_filter :set_up  
  before_filter :biller_view  
  helper_method :highlight_form_elements

  def show
    respond_to do |format|
      format.js do
        if @gateway = TornadoGateway.find_by_name(params['id'])
          @user_gateway = current_user.user_gateway(@gateway.gateway_name, true)
          render :update do |page|
            page.replace_html "#{ @gateway.gateway_name }_form", :partial => @user_gateway.form_partial, :locals => { :user_gateway => @user_gateway }
            highlight_form_elements(page)
          end
        else
          render :update do |page|
            page.replace_html 'user_gateway_message', "<div class='notice'>There is no active gateway called #{ params['id'].inspect }.</div>"
            highlight_form_elements(page)
          end
        end
      end
    end
  end

  def update
    # currently only used in simply flow
    # FIXME add error handling
    if api_token? and api_token.user_gateway
      flash[:notice] = 'Sage Payment Solutions account information updated.'
      if params[:id].to_i == api_token.user_gateway.id
        api_token.user_gateway.set_active
      else
        raise "Usergateway.update called with id (#{params[:id]}) that does not match api_token.user_gateway (#{api_token.user_gateway.inspect})"
      end
    else
      UserGateway.set(current_user, params[:user_gateways])
    end
    if api_token?
      redirect_to new_delivery_path
    else
      redirect_to profiles_url
    end
  end
  
  def index
    @show_simply_back_button = true
    if api_token?
      render :action => 'simply/index'
    end
  end
  
if %w{test development}.include?(RAILS_ENV)
  def threef
    @show_simply_back_button = true
    render :template => 'user_gateways/simply/index', :layout => 'layouts/simply/main'
  end
end

  def switch_to_sps
    render :template => 'user_gateways/simply/switch_to_sps', :layout => 'layouts/simply/main'
  end

  
  protected

  def api_token_required
    redirect_to home_url unless api_token?
    api_token?
  end

  def set_up
    @page_id = 'Settings'
  end

  def highlight_form_elements(page)
    page << %{
      $$('#user_gateway label *').each(function(element) {
        Sage.highlight_element(element);
      });
    }
  end
  
  
  
end
