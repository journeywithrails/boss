class BeanStreamInteracGateway < TornadoGateway
  class << self
    def display_name
      'Beanstream INTERAC Online Gateway'
    end

    def display_recipient_name
      'INTERAC Online'
    end

    def gateway_name
      'beanstream_interac'
    end

    def supported_payment_types
      [:interac]
    end

    def supported_currencies
      ['CAD', 'USD']
    end

    def position
      2.5
    end

    def gateway_class
      ActiveMerchant::Billing::BeanstreamInteracGateway
    end

    def enabled?
      ::AppConfig.payments.beanstream_interac.enabled
    end

    def user_gateway
      BeanStreamInteracUserGateway
    end

    def selection_text
      %{Merchant INTERAC Online service from Beanstream <span class="details">...</span>}
    end

    def tease_text
      _("<a href='/beanstream_help.html' target='new'>learn more & sign up</a>")
    end

    def payment_text
      %{INTERAC Online service from Beanstream}
    end

    # Allows payment state to go directly from created to clearing if true
    def single_call?
      true
    end
  end

  def handle_invoice?(invoice)
    if ug = invoice.user_gateway(gateway_name)
      ug.currency == invoice.currency
    end
  end

  def complete_purchase(controller, access_key, payment_data)
    urls = controller.beanstream_interac_response_urls(access_key)
    @approved_url = urls[:approved_url]
    @declined_url = urls[:declined_url]
    response = submit_payment_request(payment_data)
    # Overwritten here because success only means success in step 1 of 2
    # and the request is still in process until the result comes back
    # and process_gateway_result is called.
    unless response.success?
      payment.error_details = response.inspect
      payment.fail!
    end
    # define a method on the response that the controller uses to know
    # how to use their 'redirect' which is a javascript redirect (?!)
    def response.custom_render(controller)
      # redirect here is the response #redirect method
      # beanstream_interac_redirect is defined in the 
      # BeanstreamInteracControllerActions module
      controller.beanstream_interac_redirect(redirect)
    end
    response
  end

  # request should be the result of the controller's #request method
  def process_gateway_result(request)
    response = handle_exception(payment) do
      transaction = request.raw_post
      if transaction.blank?
        transaction = request.query_string
      end
      gateway.confirm(transaction)
    end
    process_payment_response(response)
  end

  def initialize_payment_data(params)
    billing_address = BillingAddress.new(params[:billing_address])
    return [billing_address]
  end

  def cancelable?(payment)
    true
  end

  protected

  def trace_payment_request(payment_data)
    billing_address = payment_data.first
    logger.debug 'Making payment request with:'
    logger.debug "Amount: #{ amount_as_cents } cents"
    logger.debug [billing_address].inspect
    logger.debug request_parameters(payment_data).inspect
  end

  def payment_data_valid?(payment_data)
    billing_address = payment_data.first
    billing_address.valid?
  end

  def payment_data_types
    [BillingAddress]
  end

  def gateway_class
    ActiveMerchant::Billing::BeanstreamInteracGateway
  end

  def request_parameters(payment_data)
    billing_address = payment_data.first
    [{ :order_id => order_id,
      :billing_address => billing_address,
      :email => billing_address.email,
      :subtotal => Cents.new(:dollars => invoice.subtotal_amount),
      :shipping => 0,
      :tax1 => Cents.new(:dollars => invoice.gst),
      :tax2 => Cents.new(:dollars => invoice.pst),
      :custom => invoice.description_for_paypal,
      :approved_url => @approved_url,
      :declined_url => @declined_url}]
  end
end
