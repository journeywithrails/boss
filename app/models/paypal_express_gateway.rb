class PaypalExpressGateway < TornadoGateway
  class << self
    def display_name
      'PayPal Express Gateway'
    end

    def gateway_name
      'paypal_express'
    end

		def display_recipient_name
			'PayPal'
    end

    def supported_payment_types
      [:paypal_express]
    end

    def supported_currencies
      PaypalGateway.supported_currencies
    end

    def position
      4.0
    end

    def enabled?
      ::AppConfig.payments.paypal_express.enabled
    end

    def user_gateway
      PaypalExpressUserGateway
    end

    def gateway_class
      ActiveMerchant::Billing::PaypalExpressGateway
    end

    # Allows payment state to go directly from created to clearing if true
    def single_call?
      false
    end
  end

  def handle_invoice?(invoice)
    true # assume paypal supports everything
  end

  def payment_url(controller, access_key)
    confirm_url, cancel_url = controller.paypal_response_urls(access_key)
    begin
      response = gateway.setup_purchase(
        amount_as_cents, 
        :currency => @payment.currency,
        :order_id => order_id,
        :custom => "#{@invoice.unique}_#{@access_key}_#{@payment.id}",
        :email => @invoice.default_recipients,
        :return_url => confirm_url,
        :cancel_return_url => cancel_url,
        :no_shipping => true,
        :description => @invoice.description_for_paypal
      )
      dawdle
      test_checkpoint_notify_and_wait(:called_setup_purchase)
    rescue Exception => e
      @payment.fail!
      @payment.update_attribute('error_details', e.inspect)
      # don't gobble errors!
      raise
    end
    
    if response.success?
      @payment.redirect_to_gateway!
      token = response.params['token']
      @payment.update_attribute('gateway_token', token)
      gateway.redirect_url_for(token)
    else
      @payment.update_attribute('error_details', response.inspect)
      @payment.fail!
      nil
    end
  end

  # called when paypal calls the return url
  def handle_confirmation(params)
    @payment.retrieve_details!
    response = gateway.details_for(params["token"])
    dawdle
    test_checkpoint_notify_and_wait(:called_retrieve_details)
    if response.success?
      unless response.params[:order_id] == @access_key
        #raise Sage::BusinessLogic::MalformedPaymentException ("access key in paypal response (#{@access_key} does not match access key in params(#{@access_key})") 
      end
      @payment.confirm!
      test_checkpoint_notify_and_wait(:finished_handle_confirmation_with_success)
      response.params
    else
      @payment.update_attribute('error_details', response.inspect)
      @payment.fail!
      false
    end
  end
  
  # called when the user clicks confirm on the confirm payment page
  def complete_purchase(params)
    @payment.confirmed!
    @payment.clear_payment!
    response = gateway.purchase(@payment.amount_as_cents, 
                                 :token => params["token"], 
                                 :payer_id => params["PayerID"])
    dawdle
    test_checkpoint_notify_and_wait(:called_purchase)
    if response.success?
      @payment.cleared!
      test_checkpoint_notify_and_wait(:finished_complete_purchase_with_success)
      response.params
    else
      @payment.update_attribute('error_details', response.inspect)
      @payment.fail!
      false
    end
  end
  
  # for testing
  def how_slow
    @how_slow ||= 3 if RAILS_ENV == 'test'
  end
  
  # for testing
  def dawdle
    if be_slow
      sleep how_slow
    end
  end

  protected 

end
