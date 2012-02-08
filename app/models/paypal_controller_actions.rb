module PaypalControllerActions
  def self.included(base)
    super
    base.module_before_filter self.name, :find_active_payment, :only => [:confirm, :complete, :cancel]
    base.module_before_filter self.name, :filter_with_invoice, :only => [:confirm, :complete, :cancel]
  end

  # This is the action called by paypal to return to our site. It shows details
  # of the payment & a confirm button.  It puts the payment into status 'confirming'
  def confirm
    uncancel = false
    if @payment.nil? # this can happen when user cancels, clicks back button, confirms payment
      if @payment = @invoice.cancelled_payment_with_gateway_token(params[:token])
        uncancel = true
      else
        cancelled_payment = @invoice.cancelled_no_redo_payment_with_gateway_token(params[:token])
        if cancelled_payment
          # when the user clicks cancel on the FIRST paypal cancel link (before login),
          # comes to tornado "payment cancelled" page, and then hits back button,
          # the redirect to paypal will fire (without hitting tornado), and the user
          # will be able to login and complete the payment. Therefore the commit action
          # needs to create a new payment if it is hit when the only existing payment
          # is in state cancelled_no_redo
          begin
            @payment = Payment.create_for_invoice(@invoice,
                                                  params[:invoice_id],
                                                  cancelled_payment.payment_type,
                                                  cancelled_payment.pay_type,
                                                  true,
                                                  { :gateway_token => cancelled_payment.gateway_token,
                                                    :gateway_token_date => cancelled_payment.gateway_token_date})
          rescue Sage::BusinessLogic::Exception::MalformedPaymentException => e
            return unable_to_process_page(e.message)
          end
        end
      end
    end
    if @payment.nil?
      raise BillingError, "confirm action called but no payment found for #{@invoice.inspect}\n\n#{ @invoice.pay_applications.map.pretty_inspect }\n\n#{ @invoice.payments.map.pretty_inspect}\n, token: #{params[:token]}"
    end
    @recipient = @payment.recipient
    @profile = @recipient.profile
    @user_gateway = @recipient.user_gateway(params[:id])
    Payment.with_process_lock(@payment, 'confirm') do |locked_payment|
      if locked_payment
        if uncancel
          locked_payment.uncancel!
        end
      end
      @payment.reload unless locked_payment
      billing_process_response(locked_payment || @payment, :created, :waiting_for_gateway) do
        if locked_payment
          timed_out? do
            unless @payment_details = locked_payment.gateway.handle_confirmation(params)  # handle double fire from paypal and/or reload
              unable_to_process_page(_("We were unable to retrieve your payment details from the PayPal gateway. Please try to complete your payment later."))
            end
          end
        else
          unable_to_process_page(_("Your payment is being processed. Please check again in a few seconds."), :confirm)
        end
      end
    end
  end

  def complete
    uncancel = false
    if @payment.nil? # this can happen when user cancels, clicks back button, confirms payment
      #look for cancelled payment
      if @payment = @invoice.cancelled_payment_with_gateway_token(params[:token])
        uncancel = true
      end
    end
    if @payment.nil?
      raise BillingError, "complete action called but no payment found for #{@invoice.inspect}\n\n#{ @invoice.pay_applications.map.pretty_inspect }\n\n#{ @invoice.payments.map.pretty_inspect}\n, token: #{params[:token]}"
    end
    Payment.with_process_lock(@payment, 'complete') do |locked_payment|
      if locked_payment
        locked_payment.uncancel! if uncancel
      end
      @payment.reload unless locked_payment
      billing_process_response(locked_payment || @payment, :confirming) do
        if locked_payment
          timed_out? do
            if locked_payment.gateway.complete_purchase(params)
              @invoice.acknowledge_payment(true)
            else
              if @payment.cancelled?
                cancel_page
              else
                unable_to_process_page(_("An error occurred and we were unable to complete your payment at this time."))
              end
            end
          end
        else
          unable_to_process_page(_("Your payment is being processed. Please check again in a few seconds."), :complete)
        end
      end
    end
  end

  def cancel
    raise BillingError, 'complete action called but no invoice found' if @invoice.nil?

    if @payment.nil? # this can happen when user cancels, clicks back button, clicks cancel again
      #look for cancelled payment
      @payment = @invoice.cancelled_payment_with_gateway_token(params[:token])
    end
    raise BillingError, "cancel action called but no payment found for #{@invoice.inspect}, token: #{params[:token]}" if @payment.nil?

    begin
      test_checkpoint_notify(:payments_cancel_will_ask_for_process_lock)
      test_checkpoint_wait(:payments_cancel_will_ask_for_process_lock)

      # we don't need to poll for the process lock, since we will do the same thing whether we get it or not
      @payment = (locked_payment = Payment.get_process_lock(@payment)) || @payment
      test_checkpoint_notify(:payments_cancel_will_ask_for_process_lock)
      locked_out = locked_payment.nil?
      if locked_out
        test_checkpoint_notify(:payments_cancel_locked_out)
        test_checkpoint_wait(:payments_cancel_locked_out)
        @payment.reload
      end
      begin # block just to ensure the pong for the payments_complete_locked_out checkpoint
        # our action is the same regardless of whether we got the process lock
        case @payment.status.to_sym
        when :confirmed, :clearing, :cleared
          return complete_page, _("The payment has already gone through and cannot be cancelled")
        else
          @payment.cancel!
          return unable_to_process_page("An error occurred.", true) unless @payment.cancelled? or @payment.cancelled_no_redo?
        end

      ensure
        test_checkpoint_notify(:payments_cancel_locked_out) if locked_out
      end

    ensure
      @payment.release_process_lock unless @payment.nil?
      $log_concurrency = false
    end
  end

  def paypal_response_urls(access_key)
    confirm_url = confirm_invoice_online_payments_url(:invoice_id => access_key)
    cancel_url = cancel_invoice_online_payments_url(:invoice_id => access_key)
    [confirm_url, cancel_url]
  end
end

OnlinePaymentsController.send :include, PaypalControllerActions
