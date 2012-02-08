class LanguagesController < ApplicationController

  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter
  
  def show
    switch_lang! params[:id]
    redirect_to :controller => '/home', :action => 'index'
  end

  def index
    redirect_to :controller => '/home', :action => 'index'
  end

  def create
    switch_lang! 
    update_customer! if params[:invoice_id]
    render :update do |page|
      page.redirect_to request.env["HTTP_REFERER"]
    end
  end

  protected
  def update_customer!
    @invoice = Invoice.find(params[:invoice_id])
    @invoice.customer.update_attribute(:language, params[:language])
  end
  
  def switch_lang!( lang = nil )
    if lang.nil?
      language = params[:language]
    else
      language = lang
    end
    current_user.update_language!(language) if logged_in?
    change_language!(language)    
  end
  
end
