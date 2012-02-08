class OnlinePaymentsController < ApplicationController
  include Sage::BusinessLogic::Exception
  include LastObelus::Concurrency::Checkpoints
  include FilterWithInvoice
  # NOTE: additional modules are included at the bottom of the file

  before_filter :filter_ensure_payment_exists_and_not_in_progress, 
                            :only => [:show,          :new]
  before_filter :filter_with_invoice, 
                            :only => [:show, :create, :new,                :retry]
  before_filter :filter_active_payment, 
                            :only => [:show, :create, :new, :payment_type, :retry]
  before_filter :filter_already_paid, 
                            :only => [:show, :create]
  before_filter :filter_valid_gateway, 
                            :only => [       :create]

  helper PaymentsHelper
  helper_method :access_key

  filter_parameter_logging "number" do |key, value|
    case key
    when 'number'
      #show only last 4 digits of ccard
      'x'*(value.length-4) + value[-4,4]
    else
      value
    end
  end
  

  def new
    billing_process_response(@payment, :created) do
      @payment.payment_type ||= @invoice.selected_payment_types.first
      respond_to do |format|
        format.html do
          render_payment_form
        end
      end
    end
  end

  def retry
    billing_process_response(@payment, :clearing) do
      if @payment.retry!
        redirect_to new_invoice_online_payment_path(access_key)
      else
        unable_to_process_page("Unable to cancel the transaction at this time. Please try again later.")
      end
    end
  end
  
  def create
    billing_process_response(@payment, :created, :error) do
      if @payment.current_state == :error
        @payment.retry!
      end
      if @invoice.selected_payment_type?(@payment.payment_type)
        valid, @payment_data = @payment.process_payment_params(params)
        if valid
          begin
            response = @payment.submit!(self, access_key, @payment_data)
            if response.success?
              if response.respond_to?(:custom_render)
                return response.custom_render(self)
              elsif response.respond_to?(:redirect) and not response.redirect.blank?
                return redirect_to(response.redirect)
              else
                @invoice.acknowledge_payment(true)
                layout_for_invoice_recipient
                if (!@invoice.created_by.nil?)
                  @profile = @invoice.created_by.profile
                end
                return render( :action => 'complete')
              end
            else
              flash[:warning] = response.message
            end
          rescue ActiveMerchant::ConnectionError, ActiveMerchant::RetriableConnectionError => e
            flash[:warning] = _("The server was unable to connect to the payment processor. If the problem persists please wait a few minutes before trying again. The specific error reported was \"%{msg}\"") % { :msg => e.message }
          rescue ActiveMerchant::ResponseError => e
            flash[:warning] = _("The payment processor returned an unexpected response. If the problem persists, please confirm with the merchant that their account is correctly configured. The specific error reported was \"%{msg}\"") % { :msg => e.message }
          rescue BillingError => e
            flash[:warning] = _("An error occurred: %{msg}") % { :msg => e.message }
          rescue MalformedPaymentException
            flash[:warning] = _("The selected payment option is not currently available. Please try again.")
          rescue Timeout::Error
            flash[:warning] = _("The request has timed out.")
          rescue Exception => e
            flash[:warning] = _("An error occurred: %{name} %{msg}") % { :name => e.class.name, :msg => e.message }
          end
        end
      else
        flash[:warning] = _("The selected payment option is not currently available. Please try again.")
      end
      render_payment_form
    end
  end

  def payment_type
    if @payment.current_state == :clearing
      return render(:nothing => true)
    end
    @payment.retry! if @payment.current_state == :error
    orig_gateway = @payment.pay_type
    @payment.payment_type = params[:payment_type]
    @payment_type = @payment.payment_type
    @gateway = @payment.gateway
    if orig_gateway == @payment.pay_type
      # still may need to save because the payment type may have changed even if the gateway didn't
      @payment.save!
      # this will need to change if the form for the same gateway is ever
      # updated on payment type changes.
      return render(:nothing => true)
    end
    @payment_data = @payment.initialize_payment_data
    respond_to do |format|
      format.js do
        @payment.payment_type = params[:payment_type]
        @payment_type = @payment.payment_type
        @gateway = @payment.gateway
        @payment.save!
        @payment_data = @payment.initialize_payment_data
      end
    end
  end

  # this was the #direct_payment path
  def show
    return if timed_out? do
      begin
        @payment_url = @payment.pay!(self, params['id'], access_key)
      rescue BillingError => e
        return unable_to_process_page(e.message)
      end
    end
    unless @payment_url.blank?
      respond_to do |format|
        format.html { redirect_to @payment_url }
        format.xml { render :text => "<url>#{ @payment_url }</url>" }
      end
    else
      return unable_to_process_page("The payment gateway is unavailable at this time")
    end
  end

  def switch_country
    @billing_address = BillingAddress.new
    if params[:billing_address].is_a?(Hash)
      @billing_address.country = params[:billing_address][:country]
      @billing_address.state = params[:billing_address][:province_state]
    end
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
  
  protected

  def render_payment_form
    unless @invoice.selected_payment_type?(@payment.payment_type)
      @payment.payment_type = @invoice.selected_payment_types.first
      @payment.save unless @payment.new_record?
    end
    @payment_type = @payment.payment_type
    @gateway = @payment.gateway
    @payment_data ||= @payment.initialize_payment_data
    layout_for_invoice_recipient
    render :action => 'new'
  end

  def filter_ensure_payment_exists_and_not_in_progress
    return @filter_ensure_payment_exists_and_not_in_progress unless @filter_ensure_payment_exists_and_not_in_progress.nil?
    begin
      if @payment = Payment.direct_payment_for_access_key(access_key, params[:id])
        @filter_ensure_payment_exists_and_not_in_progress = true
      else
        unable_to_process_page(_("A payment was already initiated. This can happen if you click the pay link multiple times."))
        @filter_ensure_payment_exists_and_not_in_progress = false
      end
    rescue ActiveRecord::RecordNotFound
      render :template => "access/not_found", :status => 404
      @filter_ensure_payment_exists_and_not_in_progress = false
    end
  end

  def find_active_payment
    # can't remember why I didn't use the call against invoice...
    #@payment ||= @invoice.active_payment_with_access_key(params[:access])
    @payment ||= Payment.find_active_with_access_key(access_key)
    @payment.ip = request.remote_ip
    true
  end

  def filter_active_payment
    find_active_payment
    if @payment and @payment.active?
      true
    else
      if @payment.nil?
        log_trace 'Payment not found' 
      else
        log_trace 'Payment was not active -- this should not happen'
      end
      respond_to do |format|
        format.html {render :template => "access/not_found", :status => 404}
        format.xml {render :text => "<error>Not Found</error>"}
      end
      false
    end
  end

  def filter_valid_gateway(first_call = true)
    if @payment.gateway
      if params[:gateway] 
        if @payment.payment_type == params[:gateway]
          true
        elsif @payment.can_change_gateway? and first_call
          @payment.payment_type = params[:gateway]
          filter_valid_gateway(false) && @payment.save
        else
          unable_to_process_page("Can not change current payment from #{ @payment.pay_type } to #{ params[:gateway] } at this time.")
        end
      else
        true
      end
    else
      unable_to_process_page("The gateway #{ params[:gateway] } is not available for this invoice")
    end
  end
  
  def filter_already_paid
    return @filter_already_paid unless @filter_already_paid.nil?
    if @invoice.fully_paid?
      respond_to do |format|
        format.html {render :template => "online_payments/already_paid",:layout=> "external_main"} 
        format.xml {render :text => "<url>#{url}</url>"}
      end
      @filter_already_paid = false
    else
      @filter_already_paid = true
    end
  end

  def billing_process_response(payment, *valid_states) 
    method, *args = payment.billing_process_response(*valid_states) { yield }
    # method will be nil or something like :unable_to_process_page
    send(method, *args) if method
  end

  def unable_to_process_page(msg=nil, try_again=false)
    @try_again = try_again
    respond_to do |format|
      flash[:notice] = msg
      format.html { render :template => 'online_payments/unable'}
      format.xml
    end
    false
  end
  
  def complete_page(msg=nil)
    respond_to do |format|
      flash[:notice] = msg
      format.html { render :template => 'online_payments/complete'}
      format.xml
    end
    false
  end
  
  def cancel_page(msg=nil)
    respond_to do |format|
      flash[:notice] = msg
      format.html { render :template => 'online_payments/cancel'}
      format.xml
    end
    false
  end

  def access_key
    # override or set @key if the key name is different!
    @key ||= params[:invoice_id] 
  end

  # returns true if it times out (opposite of the way filters work!)
  def timed_out?
    retry_times = 0
    begin
      yield
      false
    rescue Timeout::Error => e
      retry if RAILS_ENV == 'test' and (retry_times += 1) < 4
      unable_to_process_page(_("Sorry, we are unable to complete your payment at this time, as the payment service appears to be busy or down. Please wait a moment and try again."))
      true
    end
  end
end

load 'app/models/paypal_controller_actions.rb'
load 'app/models/beanstream_interac_controller_actions.rb'
