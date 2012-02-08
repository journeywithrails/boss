class ExactGateway < TornadoGateway
  class << self
    def display_name
      'E-xact Gateway'
    end

		def display_recipient_name
			'credit card'
    end

    def gateway_name
      'exact'
    end

    def supported_payment_types
      gateway_class.supported_cardtypes
    end

    def supported_currencies
      ['CAD', 'USD']
    end

    def gateway_class
      ActiveMerchant::Billing::ExactGateway
    end

    def position
      2.0
    end

    def enabled?
      ::AppConfig.payments.exact.enabled
    end

    def user_gateway
      ExactUserGateway
    end

    def selection_text
      _("Merchant service by E-xact")
    end

    def tease_text
      _("<a href='/exact_help.html' target='new'>learn more & sign up</a>")
    end

    def payment_text
      selection_text
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

  def initialize_payment_data(params)
    card = ActiveMerchant::Billing::CreditCard.new(params[:card])
    card.type = params[:payment_type]
    billing_address = BillingAddress.new(params[:billing_address])
    billing_address.exclusive_fields = [:email]
    return [card, billing_address]
  end

  protected

  def trace_payment_request(payment_data)
    credit_card, billing_address = payment_data
    logger.debug 'Making payment request with:'
    logger.debug "Amount: #{ amount_as_cents } cents"
    logger.debug credit_card.inspect
    logger.debug billing_address.inspect
    logger.debug request_parameters(payment_data).inspect
  end

  def payment_data_types
    [ActiveMerchant::Billing::CreditCard, BillingAddress]
  end

  def request_parameters(payment_data)
    credit_card, billing_address = payment_data
    [credit_card, {
      :order_id => order_id,
      :description => invoice.description_for_paypal,
      :customer => invoice.customer_name,
      :ip => payment.ip,
      :email => billing_address.email,
    }]
  end

end
