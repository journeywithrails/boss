class BeanStreamDirectDepositGateway < BeanStreamGateway
  class Check < ActiveMerchant::Billing::Check
    attr_accessor :country

    def required_fields
      if country == 'US' 
        [:country, :routing_number, :account_number]
      else
        [:country, :institution_number, :transit_number, :account_number]
      end
    end

    def include?(field_name)
      required_fields.include? field_name
    end

    def validate
      required_fields.each do |attr|
        errors.add(attr, "cannot be empty") if self.send(attr).blank?
      end
      
      if required_fields.include? :routing_number
        errors.add(:routing_number, "is invalid") unless valid_routing_number?
      end
    end
  end

  class << self
    def display_name
      'BeanStream Direct Payment Gateway'
    end

		def display_recipient_name
			'direct payment'
    end

    def gateway_name
      'beanstream_dd'
    end

    def supported_payment_types
      [:virtual_check]
    end

    def supported_currencies
      ['CAD']
    end

    def gateway_class
      ActiveMerchant::Billing::BeanstreamGateway
    end

    def position
      2.0
    end

    def enabled?
      ::AppConfig.payments.beanstream_dd.enabled
    end

    def user_gateway
      BeanStreamDirectDepositUserGateway
    end

    def selection_text
      _("Beanstream Direct Payment electronic check service")
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
    check = Check.new(params[:check])
    # Setting the check country determines which fields should be validated.
    check.country = invoice.user_gateway(gateway_name).country
    billing_address = BillingAddress.new(params[:billing_address])
    return [check, billing_address]
  end

  protected

  def payment_data_types
    [Check, BillingAddress]
  end

end
