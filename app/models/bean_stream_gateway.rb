# Before we use the beanstream gateway we need to adjust the metadata to include
# US support:
#
ActiveMerchant::Billing::BeanstreamGateway.supported_countries = ['CA', 'US']

class BeanStreamGateway < TornadoGateway
  class << self
    def display_name
      'BeanStream Gateway'
    end

		def display_recipient_name
			'credit card'
    end

    def gateway_name
      'beanstream'
    end

    def supported_payment_types
      gateway_class.supported_cardtypes
    end

    def supported_currencies
      ['CAD', 'USD']
    end

    def gateway_class
      ActiveMerchant::Billing::BeanstreamGateway
    end

    def position
      2.0
    end

    def enabled?
      ::AppConfig.payments.beanstream.enabled
    end

    def user_gateway
      BeanStreamUserGateway
    end

    def selection_text
      _("Merchant service by Beanstream")
    end

    def tease_text
      _("<a href='/beanstream_help.html' target='new'>learn more & sign up</a>")
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
      :subtotal => Cents.new(:dollars => invoice.subtotal_amount.to_f),
      :shipping => 0.0,
      :tax1 => Cents.new(:dollars => invoice.tax1),
      :tax2 => Cents.new(:dollars => invoice.tax2),
      :custom => invoice.description_for_paypal }]
  end

end
