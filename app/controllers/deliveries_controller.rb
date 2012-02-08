class DeliveriesController < ApplicationController
  include ApiTokenSupport
  include InvoicesController::RenderPdf

  prepend_before_filter CASClient::Frameworks::Rails::Filter

  before_filter :find_deliverable, :only => [:new, :create]
  before_filter :set_locale_from_customer, :only => [:create] 
  
  layout :external_layout
  
  def index
    @deliveries = current_user.deliveries
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @deliveries }
    end
  end

  def show
    get_delivery_from_api_token
    @delivery ||= current_user.deliveries.find(params[:id])
    respond_to do |format|
      format.html do
        if api_token?
          render :template => 'invoices/simply/invoice_sent'
        else
          render
        end
      end
      format.xml { render :xml => @delivery }
    end
  end

  def new
    @delivery ||= current_user.deliveries.build(params[:delivery])
    @delivery.setup_mail_options
    respond_to do |format|
      format.html do
        if request.xhr?
          @show_controls = false
          render :layout => 'dialog'
        else
          @show_controls = true
          if api_token?
            render :template => 'invoices/simply/send_invoice_preview'
          else
            render
          end
        end
      end
      format.xml { render :xml => @delivery }
    end
  end

  # todo: cleanup. dirty fix, set the locale before and after each flash message. take flash into its own method didn't help. 
  
  def create
    if @delivery.nil?
      @delivery = current_user.deliveries.build(params[:delivery])
    else
      @delivery.attributes = params[:delivery]
    end
    @delivery.setup_mail_options
    if params[:commit] == _("Cancel")
      set_locale_from_user
       flash[:notice] = _('Email delivery cancelled.')
      set_locale_from_customer
      redirect_to(:controller => @delivery.deliverable_type.tableize, :action => 'show', :id => @delivery.deliverable_id) 
    else
      respond_to do |format|
        if @delivery.valid?
          if @delivery.deliver!(self) and @delivery.save
            Activity.log_send!(@delivery, current_user)
            set_locale_from_user
              flash[:notice] = _('Email was successfully delivered.')
            set_locale_from_customer
            format.html do
              if api_token?
                redirect_to delivery_path(@delivery)
              else
                redirect_to(:controller => @delivery.deliverable_type.tableize, :action => 'show', :id => @delivery.deliverable_id)
              end
            end
            format.js do
              render :action => 'success', :layout => false
            end
            format.xml do
              render :xml => @delivery, :status => :created, :location => @delivery
            end
          else
            @delivery.store_errors("deliveries_controller#create -- couldn't save")
            set_locale_from_user
              flash[:notice] = _('There was a problem delivering your email.')
            set_locale_from_customer
            format.html do
              if request.xhr?
                render :action => 'unable', :layout => false
              elsif api_token?
                render :action => 'unable'
              else
                render :action => 'unable'
              end
            end
            format.xml do
              render :xml => @delivery.errors, :status => :unprocessable_entity
            end
          end
        else
          format.html do
            if api_token?
              render :action => 'unable'
            else
              render(:action => 'new', :layout => !request.xhr?, :status => :unprocessable_entity) 
            end
          end
          format.xml do
            render :xml => @delivery.errors, :status => :unprocessable_entity 
          end
        end
      end
    end
  end

  def destroy
    @delivery = current_user.deliveries.find(params[:id])
    @delivery.destroy
    respond_to do |format|
      format.html { redirect_to(deliveries_url) }
      format.xml { head :ok }
    end
  end

  def unable
    @delivery = current_user.deliveries.find(params[:id]) unless params[:id].blank?
  end
  
  protected

  # RADAR: this means delivery only works with entities who have created_by set
  def find_deliverable
    RAILS_DEFAULT_LOGGER.debug("find_deliverable")    
    if api_token?      
      get_delivery_from_api_token
    else
      RAILS_DEFAULT_LOGGER.debug("not in api")      
      param = params[:delivery]
      if param and not param[:deliverable_type].blank? and not param[:deliverable_id].blank?
        klass = param[:deliverable_type].constantize
        @deliverable = klass.find(:first, :conditions => { :id => param[:deliverable_id], :created_by_id => current_user.to_param })
        unless @deliverable
          flash[:warning] = _("%{something} doesn't exist") % { :something => param[:deliverable_type]}
        end
      end
    end
    RAILS_DEFAULT_LOGGER.debug("@deliverable: #{@deliverable.inspect}")
    unless @deliverable and @deliverable.sendable?(flash)
      if request.xhr?
        render :action => 'unable', :layout => 'dialog' 
      else
        redirect_to(unable_deliveries_url)
      end
    end
    @deliverable
  end

  def get_delivery_from_api_token
    if api_token?
      if @delivery = api_token.delivery
        @deliverable = @delivery.deliverable
      end
    end
  end
  
  def set_locale_from_user
    if @deliverable.is_a? Invoice
      set_locale(set_locale(cookies["LANG"] || AppConfig.default_language))
    end
  end
  
  def set_locale_from_customer
    puts "set_locale_from_customer" if $log_on
    if @deliverable.is_a? Invoice
      puts "setting locale to #{@deliverable.customer.language}" if $log_on
      set_locale(@deliverable.customer.language)
    end
  end
  
end
