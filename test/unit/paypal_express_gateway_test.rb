require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../billing_helper'

class PaypalExpressGatewayTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

  def setup
    @pp_gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(:login => 'cody', 
                                                                    :password => 'test',
                                                                    :pem => 'not_blank')
    @test_token = '1234567890'
    ActiveMerchant::Billing::Base.gateway_mode = :test
    @payment = Payment.new
    @payment.stubs(:valid?).returns(true)
    @payment.stubs(:amount_as_cents).returns(100)
    @payment.save!    
    @invoice = Invoice.new
    @invoice.stubs(:description_for_paypal).returns('test')
    @invoice.stubs(:payment_gateway_credentials).returns(:login => paypal_test_api_username,
                                                         :password => paypal_test_api_password,
                                                         :signature => paypal_test_api_key)
    @gateway = PaypalExpressGateway.new
    @gateway.invoice = @invoice
    @gateway.access_key = '123'
    @gateway.gateway = @pp_gateway
  end
  
  def test_should_get_payment_url
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_setup_purchase_response)
    assert_equal paypal_express_redirect_url, request_payment_url
    assert @payment.waiting_for_gateway?
  end

	def test_display_recipient_name
		#make sure there is a description of the gateway for recipient of the invoice
		assert_not_nil PaypalExpressGateway.display_recipient_name
  end


  def test_should_store_payment_url_in_payment
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_setup_purchase_response)
    assert_equal paypal_express_redirect_url, request_payment_url
    assert @payment.waiting_for_gateway?
  end
  
  
  def test_should_handle_confirmation
    @payment.update_attribute(:status, 'waiting_for_gateway')
    @payment.expects(:has_live_token?).returns(true)
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_details_response)
    assert (details = @gateway.handle_confirmation({:token => @test_token}))
    assert details['token'] = @test_token
    assert @payment.confirming?
  end
  
  def test_should_complete_purchase
    @payment.update_attribute(:status, 'confirming')
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_authorization_response)
    @payment.expects(:apply_to_invoice!).returns(true)
    assert (details = @gateway.complete_purchase({:token => @test_token, :payer_id => 'FWRVKNRRZ3WUC'}))
    assert_equal @test_token,  details['token']
    assert @payment.cleared?
  end

  def test_should_fail_payment_and_store_details_when_exception_on_payment_url
    @gateway.payment = @payment
    @pp_gateway.expects(:setup_purchase).raises(StandardError.new('something went wrong!'))
    assert_raises StandardError do
      request_payment_url
    end
    @payment.reload
    assert @payment.error?
    assert_equal '#<StandardError: something went wrong!>', @payment.error_details 
  end
  
  def test_should_fail_to_payment_url_on_payment_in_progress
    @payment.update_attribute('status', 'authorizing')
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_setup_purchase_response)
    assert_raises CantPerformEventException do
      dont_care = request_payment_url
    end
  end
  
  def test_should_fail_payment_when_setup_purchase_response_not_success
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(unsuccessful_setup_purchase_response)
    assert_nil request_payment_url
    @payment.reload
    assert @payment.error?
    assert_match 'Security header is not valid', @payment.error_details
    
  end
  
  def test_should_raise_when_cant_fail_payment_when_setup_purchase_response_not_success
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(unsuccessful_setup_purchase_response)
    
    @payment.expects(:fail!).raises(CantPerformEventException.new(@payment, :fail))
    assert_raises CantPerformEventException do
      url = request_payment_url
    end
    assert_match 'Security header is not valid', @payment.error_details
    @payment.reload
  end

  def test_should_raise_when_cant_fire_retrieve_details_in_handle_confirmation
    @gateway.payment = @payment
    @pp_gateway.expects(:details_for).never
    @payment.expects(:retrieve_details!).raises(CantPerformEventException.new(@payment, :retrieve_details))
    assert_raises CantPerformEventException do
      token, dont_care = @gateway.handle_confirmation({:token => @test_token})
    end
  end

  def test_should_fail_payment_when_details_for_response_not_success
    @gateway.payment = @payment
    @payment.update_attribute('status', 'waiting_for_gateway')
    @pp_gateway.expects(:ssl_post).returns(unsuccessful_details_for_response)
    deny @gateway.handle_confirmation({:token => @test_token})
    @payment.reload
    assert @payment.error?
    assert_match 'Security header is not valid', @payment.error_details  
  end
  
  def test_should_raise_when_cant_fail_payment_when_details_for_response_not_success
    @gateway.payment = @payment
    @payment.update_attribute('status', 'waiting_for_gateway')
    @pp_gateway.expects(:ssl_post).returns(unsuccessful_details_for_response)
    @payment.expects(:fail!).raises(CantPerformEventException.new(@payment, :fail))
    assert_raises CantPerformEventException do
      dont_care = @gateway.handle_confirmation({:token => @test_token})
    end
  end
  
  def test_should_raise_when_cant_fire_clear_payment_in_complete_purchase
    @gateway.payment = @payment
    @pp_gateway.expects(:purchase).never
    @payment.expects(:confirmed!).raises(CantPerformEventException.new(@payment, :confirmed))
    assert_raises CantPerformEventException do
      dont_care = @gateway.complete_purchase({:token => @test_token})
    end
  end

  def test_should_fail_payment_when_purchase_response_not_success
    @gateway.payment = @payment
    @payment.update_attribute('status', 'confirming')
    @pp_gateway.expects(:ssl_post).returns(unsuccessful_purchase_response)
    deny @gateway.complete_purchase({:token => @test_token})
    @payment.reload
    assert @payment.error?
    assert_match 'Security header is not valid', @payment.error_details  
  end
  
  def test_should_raise_when_cant_fail_payment_when_purchase_not_success
    @gateway.payment = @payment
    @payment.update_attribute('status', 'confirming')
    @pp_gateway.expects(:ssl_post).returns(unsuccessful_purchase_response)
    @payment.expects(:fail!).raises(CantPerformEventException.new(@payment, :fail))
    assert_raises CantPerformEventException do
      dont_care = @gateway.complete_purchase({:token => @test_token})
    end
  end
  
  def test_should_raise_when_cant_fail_payment_when_cant_clear_payment_after_successful_purchase
    @gateway.payment = @payment
    @payment.update_attribute('status', 'confirming')
    @pp_gateway.expects(:ssl_post).returns(successful_authorization_response)
    @payment.expects(:cleared!).raises(CantPerformEventException.new(@payment, :cleared))
    assert_raises CantPerformEventException do
      dont_care = @gateway.complete_purchase({:token => @test_token})
    end
  end
  
  def test_should_store_token_in_payment
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_setup_purchase_response('bob'))
    request_payment_url
    assert_equal 'bob', @payment.gateway_token
  end

  def request_payment_url
    controller = mock('controller')
    controller.expects(:paypal_response_urls).with(@test_token).returns(['http://confirm', 'http://cancel'])
    @gateway.payment_url(controller, @test_token)
  end

  def test_should_dawdle
    @gateway.payment = @payment
    @payment.stubs(:gateway).returns @gateway
    @pp_gateway.expects(:ssl_post).returns(successful_setup_purchase_response('bob'))
    assert_dawdled { request_payment_url }
    @pp_gateway.expects(:ssl_post).returns(successful_details_response)
    assert_dawdled {@gateway.handle_confirmation({:token => @test_token})}
  
    @payment.update_attribute(:status, 'confirming')
    @payment.expects(:apply_to_invoice!).returns(true)
    @pp_gateway.expects(:ssl_post).returns(successful_authorization_response)
    assert_dawdled {@gateway.complete_purchase({:token => @test_token, :payer_id => 'FWRVKNRRZ3WUC'})}
  end


  def test_should_set_gateway_token_date
    @gateway.payment = @payment
    @pp_gateway.expects(:ssl_post).returns(successful_setup_purchase_response)
    assert_equal paypal_express_redirect_url, request_payment_url
    assert @payment.waiting_for_gateway?
    assert_not_nil @payment.gateway_token_date
    assert_in_delta @payment.gateway_token_date.to_i, Time.now.to_i, 1.1
  end
  
  def assert_dawdled
    @gateway.be_slow = true
    @gateway.how_slow = 0.2
    start = Time.now
    yield
    assert (Time.now - start) > 0.2    
    @gateway.be_slow = false
  end
  
end
