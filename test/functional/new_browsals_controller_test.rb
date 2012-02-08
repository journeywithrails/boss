require File.dirname(__FILE__) + '/../test_helper'

class NewBrowsalsControllerTest < ActionController::TestCase

  def setup
    stub_cas_logged_in(users(:basic_user))
  end
  
  def teardown
    $log_on = false
  end
  
  def test_create_signup
    assert_difference('ApiToken.count') do
      # the API for this method is pre-defined
      post :create, :simply_request => {
        :browsal => { 
          :browsal_type => 'SignupBrowsal',
          :start_status => 'signup'
      } }, :format => 'xml'
      assert_response :created

      token = ApiToken.last
      assert_response_location token

      # make sure the xml template is being used
      assert_match(/\A<\?xml version="1.0" encoding="UTF-8"\?>.*/, @response.body)

      # check necessary tags exist
      xmlBody = REXML::Document.new(@response.body)
      assert_equal "http://#{host_for_test}/browsals/#{ token.guid }/signup", current_url_from_xml(xmlBody)
    end
  end

  def test_create_login
    assert_difference('ApiToken.count') do
      @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("basic_user@billingboss.com:test")      
      post :create, :simply_request => {
        :browsal => {
          :browsal_type => 'SignupBrowsal',
          :start_status => 'login'
      } }, :format => 'xml'
      assert_response :created
      token = ApiToken.last
      assert_response_location token

      xmlBody = REXML::Document.new(@response.body)
      assert_equal "http://#{host_for_test}/browsals/#{ token.guid }/login", current_url_from_xml(xmlBody)
    end
  end

  def test_create_invalid
    post :create, :browsal => { :browsal_type => 'UnsupportedBrowsal' }, :format => 'xml'
    assert_response :unprocessable_entity  
    xmlBody = REXML::Document.new(@response.body)
    assert_equal "Invalid browsal type or request format", REXML::XPath.first(xmlBody, '/errors/error').text
  end

  def test_create_no_xml
    post :create, nil, :format => 'xml'
    assert_response :unprocessable_entity  
    xmlBody = REXML::Document.new(@response.body)
    assert_equal "Invalid browsal type or request format", REXML::XPath.first(xmlBody, '/errors/error').text
  end



  def test_create_send_invoice__create_user_gateway
    @controller.expects(:validate_invoice_params).returns(true)
    @controller.expects(:create_customer).yields(nil).returns(true)
    @controller.expects(:create_invoice).yields(nil)
    @controller.expects(:create_delivery)

    post :create, user_gateway_hash('Simply-US-16.0.00.1.2525-20081105'), :format => 'xml'
    assert_response :created

    current_user = assigns(:current_user)
    gateway = assigns(:user_gateway)
    assert_equal :false, current_user
    assert_not_nil gateway
    assert_equal 'sage_sbs', gateway.gateway_name
    assert_equal 'USD', gateway.currency
  end

  def test_create_send_invoice_should_have_a_location
    post :create, user_gateway_hash(nil, simply_invoice_hash), :format => 'xml'
    assert_response :created

    token = ApiToken.last
    assert_response_location(token)
  end

  def test_create_send_invoice_response
    use_basic_auth
    post :create, user_gateway_hash(nil, simply_invoice_hash), :format => 'xml'
    assert_response :created
    token = ApiToken.last
    xmlBody = REXML::Document.new(@response.body)
    assert_equal "http://#{host_for_test}/browsals/#{ token.guid }/send_invoice", REXML::XPath.first(xmlBody, '/send-invoice-browsal/current-url').text
    assert_equal({}, YAML.load(REXML::XPath.first(xmlBody, '/send-invoice-browsal/error-messages').text))
    #see SimplyModelIntegration for the metadata implementation
    #assert_nil REXML::XPath.first(xmlBody, '/send-invoice-browsal/simply-accounting-invoice/metadata').text
    #assert_equal "C000000000111111111122222222223", REXML::XPath.first(xmlBody, '/send-invoice-browsal/customer/metadata').text
  end

  def test_create_send_invoice_should_create_objects_not_logged_in
    post :create, user_gateway_hash(nil, simply_invoice_hash('login')), :format => 'xml'
    assert_response :created

    token = ApiToken.last
    assert_equal token, assigns(:api_token)
    assert_equal 'simply:send_invoice', token.mode
    assert_equal 'en', token.language
    customer = assigns(:customer)
    invoice = assigns(:invoice)
    delivery = assigns(:delivery)
    user_gateway = assigns(:user_gateway)
    assert_equal invoice, token.invoice
    assert customer
    assert invoice
    assert delivery
    assert user_gateway
    assert_no_errors delivery
    assert_no_errors token
    deny customer.new_record?
    deny invoice.new_record?
    deny delivery.new_record?
    deny user_gateway.new_record?
    deny token.new_record?
    assert_equal user_gateway, token.user_gateway
    assert_equal true, token.new_gateway
  end

  def test_create_send_invoice_not_logged_in
    post :create, user_gateway_hash(nil, simply_invoice_hash('login')), :format => 'xml'
    assert_response :created
    token = ApiToken.last
    xmlBody = REXML::Document.new(@response.body)
    assert_equal "http://#{host_for_test}/browsals/#{ token.guid }/send_invoice", REXML::XPath.first(xmlBody, '/send-invoice-browsal/current-url').text
    assert_equal({}, YAML.load(REXML::XPath.first(xmlBody, '/send-invoice-browsal/error-messages').text))
  end

  def test_destroy
    token = ApiToken.create!(:language => 'en')
    delete :destroy, :id => token.guid
    assert_response :ok
    assert_response_location token
    assert_raises(ActiveRecord::RecordNotFound) { token.reload }
  end

  def test_update_received_complete
    token = ApiToken.create!(:language => 'en', :mode => 'simply:send_invoice')
    ApiToken.any_instance.expects(:clear!).with('received_complete')
    @controller.expects(:logout_current_user)
    @controller.stubs(:session).returns({:sage_user => 'basic_user'})
    @controller.stubs(:current_user).returns(users(:basic_user))
    put :update, simply_update_hash(token, 'received_complete'), :format => 'xml'
    assert_response :ok
    assert_response_location token
    xmlBody = REXML::Document.new(@response.body)
    assert_equal({}, YAML.load(REXML::XPath.first(xmlBody, '/send-invoice-browsal/error-messages').text))
    assert_equal "http://#{host_for_test}/browsals/#{ token.guid }/login", REXML::XPath.first(xmlBody, '/send-invoice-browsal/current-url').text
  end

  def test_update_received_close
    token = ApiToken.create!(:language => 'en', :mode => 'simply:send_invoice')
    ApiToken.any_instance.expects(:clear!).with('received_close')
    @controller.expects(:logout_current_user)
    @controller.stubs(:session).returns({:sage_user => 'basic_user'})
    @controller.stubs(:current_user).returns(users(:basic_user))
    put :update, simply_update_hash(token, 'received_close'), :format => 'xml'
    assert_response :ok
    assert_response_location token
    xmlBody = REXML::Document.new(@response.body)
    assert_equal({}, YAML.load(REXML::XPath.first(xmlBody, '/send-invoice-browsal/error-messages').text))
    assert_equal "http://#{host_for_test}/browsals/#{ token.guid }/login", REXML::XPath.first(xmlBody, '/send-invoice-browsal/current-url').text
  end

  def test_update_invalid
    token = ApiToken.create!(:language => 'en', :mode => 'simply:send_invoice')
    ApiToken.any_instance.expects(:clear!).never
    @controller.expects(:logout_current_user).never
    put :update, simply_update_hash(token, 'something else'), :format => 'xml'
    assert_response :unprocessable_entity
    xmlBody = REXML::Document.new(@response.body)
    assert_equal "Invalid event type", REXML::XPath.first(xmlBody, '/errors/error').text
  end

  private

  def use_basic_auth
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("basic_user@billingboss.com:test")      
  end

  def assert_response_location(token)
    assert_equal "http://#{host_for_test}/browsals/#{ token.guid }", @response.headers['Location']
  end

  def assert_no_errors(object, validate = true)
    object.valid? if validate
    assert_equal [], object.errors.full_messages
  end

  def user_gateway_hash(version = nil, hash = {:simply_request => {}})
    s = hash[:simply_request]
    s[:browsal] ||= {}
    s[:browsal][:browsal_type] ||= "SendInvoiceBrowsal"
    s[:browsal][:start_status] ||= 'send-invoice'
    s[:browsal][:language] ||= 'en'
    s[:user_gateway] = {}
    s[:user_gateway][:gateway_name] = 'sage_sbs'
    s[:user_gateway][:merchant_id] = 'merchant_id'
    s[:user_gateway][:merchant_key] = 'merchant_key'
    s[:version] = version if version
    hash
  end

  def simply_invoice_hash(start_status = 'send-invoice')
    s = {}
    s[:browsal] = {}
    s[:browsal][:browsal_type] = "SendInvoiceBrowsal"
    s[:browsal][:start_status] = start_status
    s[:browsal][:language] = 'en'
    s[:delivery] = {}
    s[:delivery][:reply_to] = "simply_accounting_user@billingboss.com"
    s[:delivery][:recipients] = "test@test.com"
    s[:delivery][:subject] = "the delivery subject"
    s[:delivery][:body] = "the delivery body"
    s[:invoice] = {}
    s[:invoice][:invoice_type] = "SimplyAccountingInvoice"
    s[:invoice][:metadata] = {}
    s[:invoice][:simply_guid] = "I0000000000111111111122222222223"
    s[:invoice][:simply_amount_owing] = 70.0
    s[:invoice][:date] = Date.today
    s[:invoice][:due_date] = Date.today
    s[:invoice][:unique] = "987654321"
    s[:invoice][:reference] = "123456789"
    s[:invoice][:subtotal_amount] = 100.0
    s[:invoice][:discount_before_tax] = true
    s[:invoice][:discount_type] = "amount"
    s[:invoice][:discount_value] = 10.0
    s[:invoice][:discount_amount] = 10.0
    s[:invoice][:total_amount] = 103.50
    s[:invoice][:currency] = "CAD"
    s[:invoice][:description] = "Simply Invoice Description"
    s[:invoice][:customer] = {}
    s[:invoice][:customer][:metadata] = {}
    s[:invoice][:customer][:metadata][:guid] = "C000000000111111111122222222223"
    s[:invoice][:customer][:name] = "customer name"
    s[:invoice][:customer][:contact_name] = "contact name"
    s[:invoice][:customer][:preferred_language] = "en"
    s[:invoice][:taxes] = []
    s[:invoice][:taxes][0] = {}
    s[:invoice][:taxes][0][:name] = "Tax1"
    s[:invoice][:taxes][0][:rate] = 10.0
    s[:invoice][:taxes][0][:included] = true
    s[:invoice][:taxes][0][:amount] = 9.0
    s[:invoice][:taxes][0][:tax_on_tax] = []
    s[:invoice][:taxes][0][:tax_on_tax][0] = {}
    s[:invoice][:taxes][0][:tax_on_tax][0][:tax_name] = "Tax2"
    s[:invoice][:taxes][1] = {}
    s[:invoice][:taxes][1][:name] = "Tax2"
    s[:invoice][:taxes][1][:rate] = 5.0
    s[:invoice][:taxes][1][:included] = true
    s[:invoice][:taxes][1][:amount] = 4.5
    s[:invoice][:taxes][1][:tax_on_tax] = []
    s[:invoice][:tax_amount] = 13.5
    s[:invoice][:invoice_file_attributes] = {}
    s[:invoice][:invoice_file_attributes][:content_type] = "application/pdf"
    s[:invoice][:invoice_file_attributes][:filename] = "invoice.pdf"
    s[:invoice][:invoice_file_attributes][:temp_data64] = "11111111000000001111111100000000"
    return {:simply_request => s}
  end

  def simply_update_hash(token, fire_action)
    { :id => token.guid,
      :simply_request => {
        :version => 'Simply-US-16.00.0.0109-071209',
        :browsal => {
          :fire_event => fire_action,
        }
      }
    }
  end
  
  def current_url_from_xml(xmlBody)
    REXML::XPath.first(xmlBody, '/signup-browsal/current-url').text.strip
  end
  
end
