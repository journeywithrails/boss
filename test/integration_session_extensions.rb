module IntegrationSessionExtensions
  class DeliveredEmailMock
    def message_id
      123
    end
  end

  def html_redirect
    html = Hpricot(response.body)
    html.search('//meta').first.attributes['content'].split('url=').last.sub(/http:\/\/[^\/]+/, "")
  end

  def assert_html_redirect(expected)
    assert_template '/session/redirect'
    if expected.is_a?(Regexp)
      assert_match expected, html_redirect
    else
      assert_equal expected, html_redirect
    end
  end

  def follow_html_redirect!
    get html_redirect
  end

  def current_url
    xml = Hpricot.XML(response.body)
    root = (xml/"signup-browsal")
    if root.empty?
      root = (xml/"send-invoice-browsal")
    end
    unless root.empty?
      (root/"current-url").inner_html.strip
    end
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def email_text
    assert_not_nil(last_email)
    multipart = last_email.parts.detect { |part| part.main_type == 'multipart' }
    assert_equal 2, multipart.parts.size
    multipart.parts.detect { |part| part.sub_type == 'plain' }
  end

  def current_user
    assigns(:current_user)
  end

  def assert_back_links
    html = Hpricot(response.body)
    assert_not_nil html.at('#back-link-top')
    assert_not_nil html.at('#back-link-bottom')
    assert_equal 'javascript:history.back()', html.at('#back-link-top')['href']
  end

  def received_complete!(status_url)
    put status_url, :simply_request => {
        :browsal => { :fire_event => 'received_complete' }
      }, :format => 'xml'    
    assert_response :success
    Hpricot.XML(@response.body)    
  end

  def received_close!(status_url)
    put status_url, :simply_request => {
        :browsal => { :fire_event => 'received_close' }
      }, :format => 'xml'    
    assert_response :success
    Hpricot.XML(@response.body)    
  end


  def signup_page!(next_url)
    get next_url
    # we should get sent to SAM
    assert_redirected_to_sam(:theme=>'simply', :service_url => "http://#{host_for_test}/api/simply/newuser/thankyou")
  end

  def signup!
    # don't actually go to sam, assume user was created and auto-logged in
    stub_cas_first_login('brand_new_user', 'brand_new_user@billingboss.com', 'billingboss/simply')
    service_url = sam_service_url_from_redirect_url(redirect_to_url)
    get service_url
  end

  def simulate_login!(url, user)
    CASClient::Frameworks::Rails::Filter.stubs(:check_cas_status?).returns(false)
    get url
    assert_redirected_to_cas_login
    stub_cas_logged_in(user, 'billingboss/simply')
  end
  
  def redirect_to_new_delivery!
    assert_redirected_to '/deliveries/new'
    follow_redirect!
    assert_response :success
    assert_template 'invoices/simply/send_invoice_preview'
  end

  def redirect_to_switch_to_sps!
    assert_redirected_to '/user_gateways/switch_to_sps'
    follow_redirect!
    assert_response :success
    assert_template 'user_gateways/simply/switch_to_sps'
  end

  def activate_new_sps_gateway!(api_token)
    html = Hpricot(response.body)
    assert_match %r{/user_gateways/\d+$}, html.at('form')['action']
    submit_form
    api_token.reload
    assert_equal current_user, api_token.user
    assert api_token.user_gateway.active
    assert_equal current_user.id, api_token.user_gateway.user_id
    assert_equal 1, current_user.user_gateways.find(:all, :conditions => {:active => true}).length
  end

  def edit_user_gateways!
    html = Hpricot(response.body)
    next_link = html.at('#send-invoice-later-button')['href']
    get next_link
    assert_response :success
    assert_template 'user_gateways/simply/index'
  end

  def sign_up_for_sage_vcheck!(api_token)
    api_token.reload
    assert_nil api_token.user.user_gateway('sage_vcheck')
    assert_nil api_token.user_gateway

    submit_form "sps-form" do |form|
      form.user_gateways.sage_vcheck.merchant_id = 'bob the id'
      form.user_gateways.sage_vcheck.merchant_key = 'bob the key'
    end
    assert_redirected_to '/deliveries/new'
    api_token.reload
    assert_nil api_token.user_gateway
    user_gateway = api_token.user.user_gateway('sage_vcheck')    
    assert_not_nil user_gateway
    assert_equal 'bob the id', user_gateway.merchant_id
    assert_equal 'bob the key', user_gateway.merchant_key
    follow_redirect!
    assert_template "invoices/simply/send_invoice_preview"
  end

  def sign_up_for_beanstream!(api_token)
    api_token.reload
    assert_nil api_token.user.user_gateway('beanstream')
    assert_nil api_token.user_gateway
    submit_form "beanstream-form" do |form|
      form.user_gateways.beanstream.merchant_id = 'bob the id'
      form.user_gateways.beanstream.login = 'bob the login'
      form.user_gateways.beanstream.password = 'test'
    end
    assert_redirected_to '/deliveries/new'
    api_token.reload
    assert_nil api_token.user_gateway
    user_gateway = api_token.user.user_gateway('beanstream')    
    assert_not_nil user_gateway
    assert_equal 'bob the id', user_gateway.merchant_id
    assert_equal 'bob the login', user_gateway.login
  
    follow_redirect!
    assert_template "invoices/simply/send_invoice_preview"
  end

  #########  4c  #################
  def preview_invoice!
    html = Hpricot(response.body)
    preview_invoice_url = html.at('#email-the-invoice-button')['href']
    get preview_invoice_url
    assert_response :success
    assert_template 'invoices/simply/send_invoice_preview'
  end

  def show_invoice!
    html = Hpricot(response.body)
    assert_not_nil html.at('#show-invoice')
    get html.at('#show-invoice')['href']    
    assert_template('invoices/simply/show')
  end

  def send_invoice!(generate_delivery = false)
    assert_template 'invoices/simply/send_invoice_preview'
    html = Hpricot(response.body)
    next_link = html.at('form')['action']
    assert_equal '/deliveries', next_link
    unless generate_delivery
      InvoiceMailer.expects(:deliver_simply_send).returns(DeliveredEmailMock.new)
    end
    submit_form { |f| yield f if block_given? }
    assert_redirected_to :controller => 'deliveries', :action => 'show'
    follow_redirect!
    assert_response :success
    assert_template 'invoices/simply/invoice_sent'
  end

  def send_invoice_with_payment!(pay, generate_delivery, expected_reply_to = nil)
    html = Hpricot(response.body)
    # TODO: can't be certain which inputs will be generated without the invoice obj...
   #deny (html/"input#pay_by_visa").empty?
   #assert (html/"input#pay_by_visa[@checked]").empty?
    checked_value = nil
    view_link = nil
    send_invoice!(generate_delivery) do |form|
      # seem to only be able to check the first value unless I bother with hand writing the request
      control = form['delivery[mail_options][payment_types][]']
      checked_value = control.checked_value
      if pay
        control.check
      else
        control.uncheck
      end
      yield form if block_given?
    end
    if generate_delivery
      expected_reply_to ||= users(:basic_user).email
      assert_equal [expected_reply_to], last_email.reply_to
      if pay
        assert_match(/To view or pay this invoice/, email_text.body)
      else
        assert_match(/To view this invoice/, email_text.body)
      end
      view_link = email_text.body.scan(%r{http://[^/]+(/access/\w+)}).to_s
      deny view_link.blank?
    end
    [view_link, checked_value]
  end
  
  def host_for_test
    @controller.send(:default_url_options, nil)[:host]
  end
  
end

class Test::Unit::TestCase
  def extended_session
    open_session do |sess|
      sess.extend(IntegrationSessionExtensions)
      sess.extend(CasTestHelper) # o_o
      sess.extend(SamTestHelper)
      yield sess
    end
  end
end
