class UserGateway < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id, :gateway_name
  validate :validate_gateway_name_matches_gateway
  class << self
    def to_select
      TornadoGateway.to_select
    end

    def user_gateways
      @user_gateways ||= TornadoGateway.gateways.inject({}) do |h, g|
        h[g.gateway_name] = g.user_gateway
        h
      end
    end

    def new_polymorphic(params)
      if params.is_a?(Hash)
        klass = user_gateways[params[:gateway_name]]
        klass.new(params) if klass
      end
    end

    def set(user, params)
      return [] unless params.is_a?(Hash)
      TornadoGateway.active_gateways.map do |gateway|
        param_hash = params[gateway.gateway_name]
        logger.info "\n\n\n\n ***********************************\n\n\n"
        logger.info gateway.gateway_name
        logger.info param_hash.inspect
        logger.info "\n\n\n\n ***********************************\n\n\n"
        user_gateway = new_polymorphic(param_hash.merge(:gateway_name => gateway.gateway_name, :user => user)) if param_hash
        if user_gateway and user_gateway.valid?
          add(user, user_gateway)
        elsif user_gateway.nil?
          remove(user, gateway.gateway_name)
        end
        user_gateway
      end.compact
    end

    def remove(user, gateway_name)
      UserGateway.delete_all(['user_id = ? and gateway_name = ?', user.id, gateway_name])
    end

    def add(user, user_gateway)
      remove(user, user_gateway.gateway_name)
      user.user_gateways << user_gateway
    end
    
    def find_by_gateway_name(name, include_inactive=false)
      gateway = TornadoGateway.find_by_name(name)
      params = {}
      params.merge(:conditions=>{:active=>true}) unless include_inactive
      find_by_type(gateway.user_gateway.to_s, params) if gateway
    end
  end

  def existing_copy
    if user
      user.user_gateways.detect do |ug|
        if ug.identity_attributes == identity_attributes
          if id
            ug.id && ug.id != id
          else
            ug.id
          end
        end
      end
    else
      nil
    end
  end

  def identity_attributes
    self.attributes.except('id', 'active')
  end

  def supports_currency?(currency)
    gateway.supported_currencies.include?(currency)
  end

  def valid_for?(currency, payment_type)
    types = payment_types(currency)
    types.include?(payment_type) if types
  end

  def active=(state)
    puts "active was called with #{state}" if $log_on
    write_attribute(:active, state)
  end
  
  def set_active
    if self.valid?
      self.active = true
      user.user_gateways << self
      save
    else
      false
    end
  end
  
  def digest
    require 'digest/sha1'
    h = Digest::SHA1.new
    h << self.attributes.except('type', 'id', 'active').inspect
    h.hexdigest
  end

  def form_partial
    "user_gateways/#{ gateway_name }_form"
  end

  def payment_url(invoice)
    payments_host = 
      if ::AppConfig.use_ssl
        ::AppConfig.mail.secure_host
      else
        ::AppConfig.host
      end
    "#{payments_host}/invoices/#{invoice.create_access_key}/online_payments/#{gateway_name}"
  end

  def supports?(_gateway)
    gateway == _gateway
  end

  def handle_invoice?(invoice)
    gateway.new.handle_invoice?(invoice)
  end

  def payment_types(currency)
    if supports_currency?(currency)
      gateway.supported_payment_types
    end
  end

  private

  def validate_gateway_name_matches_gateway
    if gateway_name != gateway.gateway_name
      errors.add('gateway_name', 'does not match the selected gateway')
    end
  end

end

class PaypalUserGateway < UserGateway
  validates_presence_of :email
  validates_email_format_of :email

  def params
    if valid?
      { :email => email }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def payment_url(invoice)
    "https://www.paypal.com/webscr?cmd=_xclick&amp;business=#{email}&amp;item_name=Invoice_#{invoice.unique}&amp;amount=#{invoice.total_amount}&amp;currency_code=#{invoice.currency}"
  end

  def gateway
    PaypalGateway
  end
end

class BeanStreamUserGateway < UserGateway
  class << self
    def supported_currencies
      BeanStreamGateway.supported_currencies
    end
  end

  validates_presence_of :merchant_id, :login, :password, :currency
  validates_inclusion_of :currency, :in => supported_currencies, :if => :currency

  def params
    if valid?
      # Confusingly the updated BeanStream gateway included in AM
      # shuffles these field names.
      { :login => merchant_id,
        :user => login,
        :password => password }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    BeanStreamGateway
  end

  def supports_currency?(_currency)
    super && (currency == _currency)
  end

  def country
    currency[0,2]
  end
end

class BeanStreamDirectDepositUserGateway < BeanStreamUserGateway
  def gateway
    BeanStreamDirectDepositGateway
  end

  def form_partial
    "user_gateways/beanstream_dd_form"
  end
end

class BeanStreamInteracUserGateway < BeanStreamUserGateway
  def gateway
    BeanStreamInteracGateway
  end

  def form_partial
    "user_gateways/beanstream_interac_form"
  end
end

class CyberSourceUserGateway < UserGateway
  validates_presence_of :login, :password

  def params
    if valid?
      { :login => login,
        :password => password,
        :test => (RAILS_ENV == 'test')
      }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    CyberSourceGateway
  end
end


class MonerisUserGateway < UserGateway
  validates_presence_of :login, :password

  def params
    if valid?
      { :login => login,
        :password => password }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    MonerisGateway
  end
  

end

class SageSbsUserGateway < UserGateway
  class << self
    def supported_currencies
      SageSbsGateway.supported_currencies
    end
  end

  validates_presence_of :merchant_id, :merchant_key, :currency
  validates_inclusion_of :currency, :in => supported_currencies, :if => :currency

  def params
    if valid?
      { :login => merchant_id,
        :password => merchant_key }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    SageSbsGateway
  end

  def supports_currency?(_currency)
    super && (currency == _currency)
  end
end


class ExactUserGateway < UserGateway
  class << self
    def supported_currencies
      ExactGateway.supported_currencies
    end
  end

  validates_presence_of :login, :password, :currency
  validates_inclusion_of :currency, :in => supported_currencies, :if => :currency

  def params
    if valid?
      { :login => login,
        :password => password }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    ExactGateway
  end

  def supports_currency?(_currency)
    super && (currency == _currency)
  end
end

class SageVcheckUserGateway < UserGateway
  validates_presence_of :merchant_id, :merchant_key

  def params
    if valid?
      { :login => merchant_id,
        :password => merchant_key }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    SageGateway
  end
end

class PaypalExpressUserGateway < PaypalUserGateway
  validate :validate_paypal_credentials

  # Just created this class as a way to store existing knowledge about
  # paypal express in case we decide to bring it back.
  def validate_paypal_credentials
#    gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(self.paypal_credentials)
#    response = gateway.setup_purchase(100, 
#                                      :currency => "USD", 
#                                      :return_url => "http://test.test",
#                                      :cancel_return_url => "http://test.test")
#    logger.debug "PayPal Credentials check response:"
#    logger.debug response.inspect
#    case response.message
#    when "Success"
#      true
#    when "Internal Error"
#      errors.add('', 'The PayPal gateway appears to be down, and we are unable to validate your credentials. Please try again in a moment.')
#      false
#    else
#      errors.add('', "PayPal does not recognize these credentials: #{ response.message }")
#      false
#    end
  end

  def gateway
    PaypalExpressGateway
  end

  def form_partial
    "user_gateways/paypal_form"
  end

end

class AuthorizeNetUserGateway < UserGateway
  validates_presence_of :login, :password

  def params
    if valid?
      { :login => login,
        :password => password }
    else
      raise Sage::BusinessLogic::Exception::BillingError, "User gateway settings invalid: #{ errors.full_messages.join(', ') }"
    end
  end

  def gateway
    AuthorizeNetGateway
  end
end

