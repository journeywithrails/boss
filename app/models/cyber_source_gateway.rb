class CyberSourceGateway < TornadoGateway
  class << self
    def display_name
      'CyberSource Gateway'
    end

		def display_recipient_name
			'credit card'
    end

    def gateway_name
      'cyber_source'
    end

    def supported_payment_types
      gateway_class.supported_cardtypes
    end

    def supported_currencies
      ['USD']
    end

    def gateway_class
      ActiveMerchant::Billing::CyberSourceGateway
    end

    def position
      5.0
    end

    def enabled?
      ::AppConfig.payments.cyber_source.enabled
    end

    def user_gateway
      CyberSourceUserGateway
    end

    def selection_text
      _("Merchant service by CyberSource")
    end

    def tease_text
      _("Process payment through CyberSource")
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
    self.class.supported_currencies.include? invoice.currency
  end

  def initialize_payment_data(params)
    card = ActiveMerchant::Billing::CreditCard.new(params[:card])
    card.type = params[:payment_type]
    billing_address = BillingAddress.new(params[:billing_address])
    billing_address.exclude_fields = [:name, :phone, :fax]
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
    [credit_card, { :order_id => order_id,
      :billing_address => billing_address,
      :email => billing_address.email,
      :currency => invoice.currency,
      :line_items => [
        {
          :declared_value => Cents.new(:dollars => invoice.subtotal_amount.to_f),
          :quantity => 1,
          :description => invoice.description_for_paypal
        }
      ]
    }]
  end

end
