class TornadoGateway
  attr_accessor :payment, :gateway, :invoice, :access_key
  attr_accessor :be_slow, :how_slow, :semaphore # for testing

  include Sage::BusinessLogic::Exception
  include LastObelus::Concurrency::Checkpoints

  class << self
    def gateways
      [
        PaypalGateway,
        PaypalExpressGateway,
        SageGateway,
        BeanStreamInteracGateway,
        SageSbsGateway,
        BeanStreamGateway,
        CyberSourceGateway,
        AuthorizeNetGateway,
        ExactGateway,
        BeanStreamDirectDepositGateway,
        MonerisGateway
      ].
        sort_by { |g| g.position }
    end

    def active_gateways
      gateways.select { |g| g.enabled? }
    end

    def to_select
      [[_("– Not Applicable –"), ""]] +
        active_gateways.map { |g| [g.display_name, g.gateway_name] }
    end

    def active?(gateway_name)
      active_gateways.any? { |g| g.gateway_name == gateway_name }
    end

    def find_by_name(gateway_name)
      active_gateways.find { |g| g.gateway_name == gateway_name }
    end

    def payment_type_name(payment_type)
      { 'visa' => 'Visa',
        :visa => 'Visa',
        'master' => 'MasterCard',
        :master => 'MasterCard',
        'american_express' => 'American Express',
        :american_express => 'American Express',
        'diners_club' => 'Diner\'s Club',
        :diners_club => 'Diner\'s Club',
        'discover' => 'Discover',
        :discover => 'Discover',
        'jcb' => 'JCB',
        :jcb => 'JCB',
        'virtual_check' => 'Virtual Check',
        :virtual_check => 'Virtual Check',
        'paypal' => 'Paypal',
        :paypal => 'Paypal',
        'paypal_express' => 'Paypal Express',
        :paypal_express => 'Paypal Express',
        'interac' =>'INTERAC Online',
        :interac =>'INTERAC Online'
      }[payment_type]
    end
  end

  def complete_purchase(controller, access_key, payment_data)
    response = submit_payment_request(payment_data)
    process_payment_response(response)
  end

  def gateway
    raise BillingError, _("The payment has not been set") if @payment.nil?
    raise BillingError, _("The invoice has not been set") if  @invoice.nil?
    return @gateway if @gateway
    credentials = @invoice.payment_gateway_credentials(gateway_name)
    raise BillingError, _("The recipient's account is misconfigured") if credentials.nil?
    @gateway ||= gateway_class.new(credentials)
  end

  def handle_invoice?(invoice)
    raise NotImplemented, _('set currency rules for payment provider')
  end

  def order_id
    @invoice.unique_for_paypal + "-" + ("%08d" % @payment.id) + ((RAILS_ENV=='test') ? Time.now.to_s : '')
  end

  def amount_as_cents
    [@payment.amount_as_cents, @payment.max_invoice_amount].min
  end
  
  def form_partial
    "online_payments/#{ gateway_name }_form"
  end

  def gateway_class
    self.class.gateway_class
  end

  def supported_cardtypes
    gateway_class.supported_cardtypes.map { |t| t.to_s }
  end

  def supported_currencies
    gateway_class.supported_currencies
  end

  def gateway_name
    self.class.gateway_name
  end

  def logger
    RAILS_DEFAULT_LOGGER
  end

  def process_payment_params(params)
    payment_data = initialize_payment_data(params)
    return [payment_data_valid?(payment_data), payment_data]
  end

  # Overwrite this method in subclasses
  def initialize_payment_data(params)
    []
  end

  # Overwrite this method in subclasses if there are any special rules
  def payment_data_valid?(payment_data)
    payment_data.map { |x| x.valid? }.all?
  end

  def cancelable?(payment)
    false
  end

  protected

  def handle_exception(payment)
    yield
  rescue Exception => e
    logger.debug "Error raised during payment: #{ e.inspect }"
    payment.error_details = e.inspect
    payment.fail!
    # don't gobble errors!
    raise
  end

  def submit_payment_request(payment_data)
    handle_exception(payment) do
      trace_payment_request(payment_data)
      validate_payment_data!(payment_data)
      payment.clear_payment!
      gateway.purchase(amount_as_cents, *request_parameters(payment_data))
    end
  end

  def process_payment_response(response)
    if response.success?
      payment.gateway_token = response.params['token']
      payment.cleared!
    else
      payment.error_details = response.inspect
      payment.fail!
    end
    response
  end

  def validate_payment_data!(payment_data)
    validate_payment_data_types!(payment_data)
    unless payment_data_valid?(payment_data)
      raise ArgumentError.new(_("Invalid payment data"))
    end
  end

  # Overwrite this method in subclasses
  def payment_data_types
    []
  end

  def validate_payment_data_types!(payment_data)
    unless payment_data.length == payment_data_types.length and payment_data_types.zip(payment_data).all? { |klass, inst| inst.is_a? klass }
      raise ArgumentError.new("Expected #{ payment_data_types.inspect }, got\n  #{ payment_data.inspect }")
    end
  end
end

