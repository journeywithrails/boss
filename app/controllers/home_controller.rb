class HomeController < ApplicationController
  layout 'homepage'

  #prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter

  caches_page :index, :if => Proc.new { |controller| !controller.logged_in? }


  def index
    @at_home = true
    @custom_title  = _("Billing Boss - Online Invoicing")
    render_mobile(:mobile_layout => "external_mobile")

  end
  
  def faq
    render :layout=>'external_main'
  end

  def about
    render :layout=>'external_main'
  end

  def tour
    render_with_a_layout("tour", "external_main")
  end
  
  def bookkeeper
    render :layout=>'external_main'
  end


end
