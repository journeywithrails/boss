class MonerisGateway < TornadoGateway
  class << self
    def display_name
      'Moneris Gateway'
    end

		def display_recipient_name
			'credit card'
    end

    def gateway_name
      'moneris'
    end

    def supported_payment_types
      gateway_class.supported_cardtypes
    end

    def supported_currencies
      ['CAD']
    end

    def gateway_class
      ActiveMerchant::Billing::MonerisGateway
    end

    def position
      3.0
    end

    def enabled?
      ::AppConfig.payments.moneris.enabled
    end

    def user_gateway
      MonerisUserGateway
    end

    def selection_text
      _("Merchant service by Moneris")
    end

    def tease_text
      _("<small>(Canadian Dollar)</small> Process payment through Moneris")
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
    invoice.currency == 'CAD'
  end

  def initialize_payment_data(params)
    card = ActiveMerchant::Billing::CreditCard.new(params[:card])
    card.type = params[:payment_type]
    billing_address = BillingAddress.new(params[:billing_address])
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
      :sub_total => Cents.new(:dollars => invoice.subtotal_amount.to_f),
      :shipping_total => '0.0',
      :gst_total => Cents.new(:dollars => invoice.gst),
      :province_tax_total => Cents.new(:dollars => invoice.pst),
      :ref1 => invoice.description_for_paypal }]
  end

end
