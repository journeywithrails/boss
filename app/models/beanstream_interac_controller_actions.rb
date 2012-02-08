module BeanstreamInteracControllerActions
  include Sage::BusinessLogic::Exception

  def self.included(base)
    super
    actions = { :only => [:beanstream_interac_approved, :beanstream_interac_declined, :interac_funded, :interac_notfunded] }
    base.prepend_before_filter :beanstream_interac_response_setup, :only => [:interac_funded, :interac_notfunded]
    base.skip_before_filter :verify_authenticity_token, :only => [:interac_funded, :interac_notfunded]
    base.module_before_filter self.name, :filter_with_invoice, actions
    base.module_before_filter self.name, :find_active_payment, actions
  end

  def beanstream_interac_approved
    billing_process_response(@payment, :clearing) do
      @gateway = @payment.gateway
      begin
        session[:interac_access_key] = nil
        response = @gateway.process_gateway_result(request)
        if response.success?
          @invoice.acknowledge_payment(true)
          return render(:action => 'complete')
        else
          flash[:warning] = %{The Interac Online payment was declined with the error "#{response.message }"}
        end
      rescue BillingError => e
        flash[:warning] = "An error occurred: #{ e.message }"
      rescue Timeout::Error
        flash[:warning] = "The request has timed out."
      end
      redirect_to new_invoice_online_payment_path(access_key)
    end
  end

  def beanstream_interac_declined
    billing_process_response(@payment, :clearing) do
      session[:interac_access_key] = nil
      @payment.fail!
      flash[:warning] = "The Interac Online payment was declined."
      redirect_to new_invoice_online_payment_path(access_key)
    end
  end

  def interac
    render :text => flash[:interac_redirect]
  end

  def interac_funded
    beanstream_interac_approved
  end

  def interac_notfunded
    beanstream_interac_declined
  end
  
  def beanstream_interac_response_urls(access_key)
    { :approved_url => beanstream_interac_approved_invoice_online_payments_url(:invoice_id => access_key),
      :declined_url => beanstream_interac_declined_invoice_online_payments_url(:invoice_id => access_key) }
  end

  def beanstream_interac_redirect(interac_redirect)
    flash[:interac_redirect] = interac_redirect
    session[:interac_access_key] = access_key
    redirect_to(interac_path)
  end

  protected

  def beanstream_interac_response_setup
    @key = session[:interac_access_key]
  end
end

OnlinePaymentsController.send :include, BeanstreamInteracControllerActions
