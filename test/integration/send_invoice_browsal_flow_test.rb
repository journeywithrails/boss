require "#{File.dirname(__FILE__)}/../test_helper"

class SendInvoiceBrowsalFlowTest < ActionController::IntegrationTest
  include SimplyApiTestHelpers
  fixtures :users

  def setup
    reset_deliveries
  end

  # Tests Flow 3a -> 3d -> 4c -> 4d4
  # Then sends same invoice again, with auth: 4c -> 4d
  # Then sends same invoice again with login
  def test_send_invoice_flow_with_signup_and_no_sps
    api_token, current_url, token_url = initiate_send_invoice('signup')
    first_invoice = api_token.invoice
    assert_not_nil first_invoice
    current_user = nil
    session_successfully_create_user(api_token, current_url) do |first_user|
      current_user = first_user.current_user
      assert_not_nil current_user
      first_user.preview_invoice!
      first_user.send_invoice!(true)
      first_user.received_complete!(token_url)
    end
    reset!

    assert_difference('Invoice.count') do
      api_token, current_url, token_url = initiate_send_invoice('send_invoice', current_user.email)
    end
    second_invoice = api_token.invoice
    assert_not_nil second_invoice
    assert_not_equal first_invoice, second_invoice
    first_invoice.reload
    #assert_equal second_invoice, first_invoice.superceded_by
    extended_session do |second_user|
      second_user.get current_url
      assert_equal current_user, second_user.current_user
      second_user.redirect_to_new_delivery!
      second_user.send_invoice!(true)
      assert_last_delivery_had_no_errors
      second_user.received_complete!(token_url)
    end
    reset!

    assert_difference('Invoice.count') do
      api_token, current_url, token_url = initiate_send_invoice('login')
    end
    third_invoice = api_token.invoice
    second_invoice.reload
    assert_not_equal second_invoice.id, third_invoice.id
    assert_state(second_invoice, :sent)
    assert_nil second_invoice.superceded_by

    session_successfully_login(api_token, current_url, nil, current_user.email) do |third_user|
      assert_equal current_user, third_user.current_user
      second_invoice.reload
      assert_state(second_invoice, :sent)
      third_user.send_invoice!(true)
      second_invoice.reload
      assert_state(second_invoice, :superceded)
      assert_equal second_invoice.superceded_by, third_invoice
      assert_last_delivery_had_no_errors
      third_user.received_complete!(token_url)
    end
  end
  
  def test_signup_and_preview_invoice_and_get_pdf
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.preview_invoice!
      html = Hpricot(user.response.body)
      pdf_link = html.at('#simply_invoice_pdf_link')['href']
      assert_match(%r{^/invoices/\d+\.pdf$}, pdf_link)
      user.get pdf_link, nil, 'Accept' => 'application/pdf,*/*'
      user.assert_response :success
      assert_equal "application/pdf", user.response.headers["type"]
      assert_match /MediaBox/, user.response.body
    end
  end

  # NOTE: the test named test_send_invoice_flow_with_login_and_no_sps was deleted because
  # test_SA_login_clicks_complete_at_invoice_sent in send_invoice_browsal_status_test is identical.
  # 4c -> 4d

  def test_send_invoice_flow_with_valid_auth_and_no_sps
    # make request without a start_status, should default to send_invoice
    api_token, current_url, token_url = initiate_send_invoice(nil, :authorized)
    extended_session do |user|
      user.get current_url
      user.redirect_to_new_delivery!
      reset_deliveries
      user.send_invoice!(true)
      assert_last_delivery_had_no_errors
      user.received_complete!(token_url)
      assert_equal [users(:basic_user).email], user.last_email.reply_to
      assert_match(/To view this invoice/, user.email_text.body)
    end
  end
  
  def test_send_invoice_flow_with_payment_link_with_user_views_invoice
    api_token, current_url, token_url = initiate_send_invoice(nil, :authorized)
    assert_nil api_token.user
    add_beanstream_gateway_to_user(users(:basic_user))
    pay_link = nil
    extended_session do |user|
      user.get current_url
      user.redirect_to_new_delivery!
      pay_link, payment_type = user.send_invoice_with_payment!(true, true)
      assert_last_delivery_had_no_errors
    end

    open_session do |recipient|
      recipient.get pay_link
      recipient.assert_redirected_to :controller => :invoices, :action => :display_invoice
      recipient.follow_redirect!
      recipient.assert_response :success    
      html = Hpricot(recipient.response.body)
      assert_equal '70.00', ((html/'span#invoice_total')/'strong').inner_html.strip
      assert_match(%r{/invoices/\w+/online_payments/new}, recipient.response.body)
      # TODO: go on to the pay page?
    end
  end
  
  def test_send_invoice_flow_with_NO_payment_link_with_user_views_invoice
    api_token, current_url, token_url = initiate_send_invoice(nil, :authorized)
    assert_nil api_token.user
    add_beanstream_gateway_to_user(users(:basic_user))
    extended_session do |user|
      user.get current_url
      api_token.reload
      assert_equal users(:basic_user), api_token.user
      user.redirect_to_new_delivery!
      user.send_invoice_with_payment!(false, true)
      assert_last_delivery_had_no_errors
    end
  end

  # tests 3d->3f->4c with no change to payment settings, using back button on 3f  
  def test_send_invoice_flow_with_edit_gateways_than_back
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.edit_user_gateways!
      api_token.reload
      assert_nil api_token.user.user_gateway
      assert_nil api_token.user_gateway
      user.assert_back_links
      # should come back to 3d -- simulate back button
      user.get "/users/#{ api_token.user_id }/thankyou"
      user.assert_response :success
      user.preview_invoice!
      user.send_invoice!(true)
      assert_last_delivery_had_no_errors
    end
  end
  
  # tests 3d->3f->4c with adding payment settings. User starts with
  # no payment gateway selected and enters one on 3f
  def test_send_invoice_flow_with_edit_gateways_add_payment_credentials
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.edit_user_gateways!
      user.sign_up_for_beanstream!(api_token)
      user.send_invoice_with_payment!(true, true, "brand_new_user@billingboss.com")
      assert api_token.invoice.selected_payment_types.any?
      assert_last_delivery_had_no_errors
    end
  end
  
  # tests 3d->3f->4c with change to payment settings. User starts with
  # no paypal gateway selected and enters beanstream on 3f
  def test_send_invoice_flow_with_edit_gateways_change_payment_credentials
    api_token, current_url, token_url = initiate_send_invoice('signup', nil, :invoice => { :currency => 'USD' })
    session_successfully_create_user(api_token, current_url) do |user|
      user.edit_user_gateways!
      api_token.reload
      add_beanstream_gateway_to_user(api_token.user)
      user.sign_up_for_sage_vcheck!(api_token)
      user.send_invoice_with_payment!(true, true, "brand_new_user@billingboss.com")
      assert api_token.invoice.selected_payment_types.any?
      assert_last_delivery_had_no_errors    
    end
  end
  
  # tests 3d->3f click go there to sign up now
  def test_send_invoice_flow_with_click_go_there_now_link
    api_token, current_url, token_url = initiate_send_invoice('signup', nil)
    session_successfully_create_user(api_token, current_url) do |user|
      user.edit_user_gateways!
      html = Hpricot(user.response.body)
      assert_not_nil html.at('#beanstream-go-there-now-link')
      assert '/beanstream_help.html', html.at('#beanstream-go-there-now-link')['href']    
    end
  end
  
  # tests 4a->4b->4c->4d
  def test_send_invoice_flow_with_new_sps_info
    api_token, current_url, token_url = initiate_send_invoice('login', nil, :user_gateway => new_user_gateway_attributes)
    session_successfully_login(api_token, current_url, :switch_to_sps) do |user|
      user.activate_new_sps_gateway!(api_token)
      user.redirect_to_new_delivery!
      user.send_invoice!
      user.received_complete!(token_url)
    end
  end
  
  def test_issue_710_should_preview_invoice_after_sending
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.preview_invoice!
      user.send_invoice!(true)
      user.show_invoice!
      user.assert_back_links
    end
  end
  
  def test_issue_739_should_show_error_for_seven_figure_invoice
    browsal_request(:send_invoice, 'login', nil, :invoice => {:total_amount => '1000000', :simply_amount_owing => '1000000'}) do |api, api_token, current_url, token_url| 
      api.assert_response :unprocessable_entity
      assert_match(/Total amount must be less than 1000000/, api.response.body)
      assert_match(/Simply amount owing must be less than 1000000/, api.response.body)    
    end
  end

  private

  def new_user_gateway_attributes
    { :gateway_name => 'sage_sbs',
      :merchant_id => '123',
      :merchant_key => 'axe' }
  end

  def add_beanstream_gateway_to_user(user)
    BeanStreamUserGateway.create(:user => user,
                                 :gateway_name => 'beanstream',
                                 :merchant_id => 'a',
                                 :login => 'b',
                                 :password => 'c',
                                 :currency => 'CAD')
    assert_not_nil user.user_gateway
    assert_not_nil user.user_gateways('beanstream')
  end
  
  def reset_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
end
