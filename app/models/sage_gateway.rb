class SageGateway < TornadoGateway
  class Customer < ActiveRecord::BaseWithoutTable
    column :customer_type
    validates_presence_of :customer_type

    def customer_type
      self['customer_type'] || 'business'
    end

    def personal?
      customer_type == 'personal'
    end
  end

  class Business < ActiveRecord::BaseWithoutTable
    column :federal_tax_number
    validates_presence_of :federal_tax_number
  end

  class << self
    def display_name
      'Sage Virtual Check Gateway'
    end

		def display_recipient_name
			'electronic check'
    end

    def gateway_name
      'sage_vcheck'
    end

    def position
      1.0
    end

    def enabled?
      ::AppConfig.payments.sage.enabled
    end

    def supported_currencies
      ['USD']
    end

    def supported_payment_types
      [:virtual_check]
    end

    def user_gateway
      SageVcheckUserGateway
    end

    def selection_text
      _("Sage Electronic Check Services from Sage Payment Solutions")
    end

    def tease_text
      _("Receive payments without the use of credit cards")
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
    ['USD'].include? invoice.currency
  end

  def payment_url(controller, access_key)
    # this is the page that takes the credit card info
    controller.sage_virtual_check_response_urls(access_key)
  end

  def initialize_payment_data(params)
    check = ActiveMerchant::Billing::Check.new(params[:check])
    billing_address = BillingAddress.new(params[:billing_address])
    billing_address.validate_fields = [:address1, :city, :state, :zip, :country, :phone, :email]
    billing_address.exclude_fields = [:name, :address2]
    customer = SageGateway::Customer.new(params[:customer])
    date = Date.from_params(params['dob'], 'birth_date')
    dob = BirthDate.new(:birth_date => date) if date
    license = DriversLicense.new(params[:license])
    ssn = SocialSecurityNumber.new(params[:ssn])
    business = SageGateway::Business.new(params[:business])
    return [check, dob, license, ssn, billing_address, customer, business]
  end

  protected

  def trace_payment_request(payment_data)
    check, dob, license, ssn, billing_address, customer, business = payment_data
    logger.debug 'Making payment request with:'
    logger.debug "Amount: #{ amount_as_cents } cents"
    logger.debug check.inspect
    logger.debug [dob, license, ssn, billing_address, customer, business].inspect
    logger.debug request_parameters(payment_data).inspect
  end

  def payment_data_valid?(payment_data)
    check, dob, license, ssn, billing_address, customer, business = payment_data
    valid = check.valid? 
    valid = billing_address.valid? && valid
    valid = customer.valid? && valid
    if customer.personal?
      valid = dob.valid? && valid if dob
      valid = license.valid? && valid 
      valid = ssn.valid? && valid 
    else
      valid = business.valid? && valid
    end
    valid
  end

  def payment_data_types
    [ActiveMerchant::Billing::Check, BirthDate, DriversLicense,
      SocialSecurityNumber, BillingAddress, SageGateway::Customer,
      SageGateway::Business]
  end

  def gateway_class
    ActiveMerchant::Billing::SageVirtualCheckGateway
  end

  def request_parameters(payment_data)
    check, dob, license, ssn, billing_address, customer, business = payment_data
    [check, { 
      :drivers_license_state => license.state,
      :drivers_license_number => license.number,
      :date_of_birth => dob.birth_date,
      :ssn => ssn.number,
      :order_id => order_id,
      :billing_address => billing_address,
      :email => billing_address.email,
      :sub_total => Cents.new(:dollars => invoice.subtotal_amount.to_f),
      :tax => Cents.new(:cents => invoice.total_taxes_as_cents),
      :addenda => invoice.description_for_paypal,
      :customer_type => customer.customer_type,
      :business_federal_tax_number => business.federal_tax_number
    }]
  end
end
