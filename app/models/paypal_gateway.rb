class PaypalGateway < TornadoGateway
  class << self
    def display_name
      'PayPal Gateway'
    end

    def display_recipient_name
      'PayPal'
    end

    def gateway_name
      'paypal'
    end

    def position
      6.0
    end

    def supported_payment_types
      [:paypal]
    end

    def supported_currencies
      ["AUD","CAD","CHF","CZK","DKK","EUR","GBP","HKD","HUF","ILS","JPY","MXN",
       "NOK","NZD","PLN","SEK","SGD","USD"]
    end

    def enabled?
      ::AppConfig.payments.paypal.enabled
    end

    def user_gateway
      PaypalUserGateway
    end

    def selection_text
      _('PayPal')
    end
    
    def tease_text
      _('basic web payments without status updates or integration <a href="/paypal_help.html" target="new">learn more</a>')
    end

    def payment_text
      _("PayPal basic web payments")
    end

    # Allows payment state to go directly from created to clearing if true
    def single_call?
      false
    end
  end

  def handle_invoice?(invoice)
    self.class.supported_currencies.include?(invoice.currency)
  end

  def cancelable?(payment)
    payment.gateway_token.nil? or payment.gateway_token_date.nil? or ((Time.now - payment.gateway_token_date) > ::AppConfig.payments.paypal.token_life)
  end

  def payment_url(controller, access_key)
    # This should set the correct state of the payment and
    # return the paypal url that should be redirected to.  I believe
    # that Paypal is currently disabled so I won't bother to 
    # research exactly what needs to happen here or whether this
    # gateway is in working order.
    
        #find the invoice from the access_key
    @access_key = AccessKey.find_by_key(access_key)
    if @access_key.nil?
      return ""
    end
    url=""
    if @access_key.keyable.kind_of?(Invoice)
      @invoice = @access_key.keyable
      @email = @invoice.created_by.user_gateways.find_by_gateway_name("paypal").email

      url = "https://www.paypal.com/webscr?cmd=_xclick&business=#{@email}&item_name=Invoice_#{@invoice.unique}&amount=#{@invoice.total_amount}&currency_code=#{@invoice.currency}"
    end
    url
  end

end
