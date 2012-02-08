# This would go in an action method for signing them into their account
response = gateway.setup_express_purchase(
  @order.total_price_in_cents, # Also accepts Money objects
  :order_id => @order.id,
  :return_url => url_for(:action => "paypal_success"),
  :cancel_return_url => url_for(:action => "paypal_cancel"),
  :description => @order.description
)
if response.success?
  url = ActiveMerchant::Billing::PaypalGateway.redirect_url_for(response.params["token"])
  redirect_to url
end

# ...

# This would go in paypal_success
response = gateway.get_express_details(params["token"])
if response.success?
    @cart = Cart.find(response.params['invoice_id'])
    # Now show some kind of confirmation screen
    # After user clicks 'Confirm payment' execute something like
    # this to secure the funds:
    response = paypal_gateway.purchase(
      @order.total_price_in_cents, 
    nil, 
    :express => true,
    :token => params["token"], 
    :payer_id => params["PayerID"]
  )

    if response.success?
        # Sing and dance, etc.
    end
end


# Parser and handler for incoming Instant payment notifications from paypal. The Example shows a typical handler in a rails application. Note that this is an example, please read the Paypal API documentation for all the details on creating a safe payment controller.
# 
# Example

  class BackendController < ApplicationController
    include ActiveMerchant::Billing::Integrations

    def paypal_ipn
      notify = Paypal::Notification.new(request.raw_post)

      order = Order.find(notify.item_id)

      if notify.acknowledge
        begin

          if notify.complete? and order.total == notify.amount
            order.status = 'success'

            shop.ship(order)
          else
            logger.error("Failed to verify Paypal's notification, please investigate")
          end

        rescue => e
          order.status        = 'failed'
          raise
        ensure
          order.save
        end
      end

      render :nothing
    end
  end