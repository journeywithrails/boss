class SageSbsGateway < TornadoGateway
  class << self
    def display_name
      'Sage Card Services (US Dollar)'
    end

		def display_recipient_name
			'credit card'
    end

    def gateway_name
      'sage_sbs'
    end

    def position
      0.5
    end
    
    def supported_payment_types
      gateway_class.supported_cardtypes
    end

    def supported_currencies
      ['CAD', 'USD']
    end

    def gateway_class
      ActiveMerchant::Billing::SageBankcardGateway
    end

    def enabled?
      ::AppConfig.payments.sage_sbs.enabled
    end

    def user_gateway
      SageSbsUserGateway
    end

    def selection_text
      _("Sage Card Services by Sage Payment Solutions")
    end

    def tease_text
      _("<a href='http://www.sagespark.com/tools_services/merchant_services/payment_solutions/merchant_accounts_and_processing_services' target='_blank'>Click here</a> for more information.")
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

  def payment_url(controller, access_key)
    # this is the page that takes the credit card info
    controller.sage_sbs_response_urls(access_key)
  end

  def initialize_payment_data(params)
    card = ActiveMerchant::Billing::CreditCard.new(params[:card])
    card.type = params[:payment_type]
    billing_address = BillingAddress.new(params[:billing_address])
    billing_address.validate_fields = [:address1, :city, :state, :zip, :country, :phone, :email]
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
      :billing_address => billing_address,
      :email => billing_address.email,
      :sub_total => Cents.new(:dollars => invoice.subtotal_amount.to_f),
      :tax => Cents.new(:cents => invoice.total_taxes_as_cents),
      :addenda => invoice.description_for_paypal
    }]
  end
end
