module PaymentAcceptanceHelper
  def b
    @b ||= @user.b
  end

  def set_billing_address(opts)
    skip_attrs = opts[:skip_address_fields] || []
    b.text_field(:id, 'billing_address_name').value=('Payer Name') unless skip_attrs.include? :name
    b.text_field(:id, 'billing_address_address1').value=('Payer Address1') unless skip_attrs.include? :address1
    unless skip_attrs.include? :country
      country, state, zip = case opts[:currency]
                       when 'USD'
                         ['United States', 'CA - California', '90210']
                       else
                         ['Canada', 'ON - Ontario', 'M6J3C9']
                       end
      b.select_list(:id, 'billing_address_country').option(:text, country).select
      b.wait
      sleep 0.2
      b.select_list(:id, 'billing_address_state').option(:text, state).select unless skip_attrs.include? :state
      b.text_field(:id, 'billing_address_zip').value=('12345') unless skip_attrs.include? :zip
    else
      b.text_field(:id, 'billing_address_state').value=('state City') unless skip_attrs.include? :state
      b.text_field(:id, 'billing_address_zip').value=('12345') unless skip_attrs.include? :zip
    end
    b.text_field(:id, 'billing_address_city').value=('Payer City') unless skip_attrs.include? :city
    b.text_field(:id, 'billing_address_phone').value=('123-456-7890') unless skip_attrs.include? :phone
    b.text_field(:id, 'billing_address_email').value=('test@test.com') unless skip_attrs.include? :email
  end

  def set_credit_card(opts = {})
    b.text_field(:id, 'card_first_name').value=('Payer First')
    b.text_field(:id, 'card_last_name').value=('Payer Last')
    b.select_list(:id, 'card_year').option(:text, '2012').select
    b.text_field(:id, 'card_verification_value').value=('123')
    if opts[:valid]
      b.text_field(:id, 'card_number').value=('4030_0000_1000_1234')
      case opts[:gateway]
      when :cyber_source
        b.select_list(:id, 'billing_address_country').option(:text, 'United States').select
        b.wait
        sleep(0.2)
        b.select_list(:id, 'billing_address_state').select_value('CA')
        b.text_field(:id, 'billing_address_zip').value=('12345')
      end
    else
      b.text_field(:id, 'card_number').value=('4003_0505_0004_0005')
      case opts[:gateway]
      when :cyber_source
        b.select_list(:id, 'billing_address_country').option(:text, 'Canada').select
        b.wait
        sleep(0.2)
        b.select_list(:id, 'billing_address_state').select_value('ON')
        # ie. invalid postal code for canada
        b.text_field(:id, 'billing_address_zip').value=('12345')
      end
    end
  end

  def create_profile(usr=:basic_user)
    u = users(usr)
    u.profile.country = "Canada"
    u.profile.company_state = "British Columbia"
    u.profile.company_country = "CA"
    u.profile.company_postalcode = "V1V 1V1"
    u.profile.payment_method = '1'
    u.profile.save!
    u.save!
  end

  def add_payment_gateway(opts)
    gateway = opts[:gateway]
    @user.goto_profile_url
    b.link(:id, "user_payments_link").click
    b.wait
    b.radio(:xpath, "//input[@value='#{gateway}']").click
    b.wait
    sleep 3
    case gateway
    when :beanstream, :beanstream_interac
      b.text_field(:id, "user_gateways[#{gateway}][login]").value=("Admin")
      b.text_field(:id, "user_gateways[#{gateway}][password]").value=("Summer08")
      b.text_field(:id, "user_gateways[#{gateway}][merchant_id]").value=("169470000")
      if opts[:currency] and opts[:currency] != 'CAD'
        b.select_list(:id, "user_gateways[#{gateway}][currency]").option(:text, opts[:currency]).select
      end
    when :cyber_source
      b.text_field(:id, "user_gateways[#{gateway}][login]").value=("sage_billingboss")
      b.text_field(:id, "user_gateways[#{gateway}][password]").value=("VKmdhxroq+zsIf+O1a9RXUFNIyP4JH/AJ8n8WRbUsmRvqjKzzuo+33sn5QhdsfBmyilBN/40Navx2y0Bc36i2w0yZ5LMlp3dlJY51V1Uw35tbyXFrKzxNRs5YHNw4FQR1AHRUpdCVVHhs6ZaurRXPsegmZu1wAvp/OL2oYVuT7YGsMq4XY7PwK0s9lU/gSrNy9GwI/gkf8AnyfxZFtSyZG+qMrPO6j7feyflCF2x8GbKKUE3/jQ1q/HbLQFzfqLbDTJnksyWnd2UljnVXVTDfm1vJcWsrPE1Gzlgc3DgVBHUAdFSl0JVUeGzplq6tFc+x6CZm7XAC+n84vahhW5Ptg==")
    end
    @user.button(:name, "commit").click
    b.wait
  end

  def send_invoice(id, opts = {})
    @user.goto_invoice_url(id)
    if opts[:payment_methods]
      opts[:payment_methods].each do |pm|
        @user.checkbox(:id, "pay_by_#{pm}").set
        @user.wait
      end
    end
    @user.button(:value, 'Save').click
    sleep 3
    b.wait
    @user.link(:id, 'show-send-dialog-btn').click
    b.wait
    sleep 3
    @user.text_field(:id, 'delivery_recipients').value=('beanstream_client@billingboss.com')
    @key = @user.link(:id, 'invoice_link').name    
    @user.button(:value, 'Send').click
    b.wait
  end

  def view(in_browser = false)
    if in_browser
      filename = "tmp/view#{Time.now.to_f}.html"
      File.open(filename, 'w') do |f|
        f.puts b.html.gsub(/(src|href)\s*=\s*"\//, %{\\1="#{::AppConfig.host}/})
      end
      puts "open -a Safari.app #{filename}"
      `open -a Safari.app #{filename}`
    else
      puts b.html
    end
  end

  def logout
    @user.goto("#{::AppConfig.host}/logout")
    b.wait
  end

  def get_payment_url
    mail = get_last_sent_email
    assert_match /http:\/\/.+\/access\/.+$/, mail.body, "Payment mail should have an access link"
    url = mail.body[/http:\/\/.+\/access\/.+$/].chomp
    url=url.sub(%r{http://[^/]+(:\d+)?}, @user.site_url)
    url
  end

  def assert_payment_state(gateway, state)
    pay = Payment.find(:first, :conditions => {:pay_type => gateway.to_s })
    assert_equal state.to_s, pay.status
  end

  def view_unpaid_invoice(payment_url, opts)
    @user.goto payment_url
    b.wait
    currency = opts[:currency] || 'CAD'
    assert_equal "10.00 #{currency}", b.span(:id, "invoice_total").text
    link = b.link(:text, "Pay Invoice")
    link.click
    b.wait
  end

  def view_paid_invoice(payment_url)
    @user.goto(payment_url)
    b.wait
    sleep 3
    #verify pay invoice link does not exist
    assert !b.html.include?("Pay Invoice") , "Paid invoice link found for fully paid invoice."
  end

  def prepare_invoice_to_pay(opts)
    invoice = invoices(:invoice_with_date_and_due_date)
    if opts[:currency]
      invoice.update_attribute :currency, opts[:currency]
    end
    create_profile
    add_payment_gateway opts
    send_invoice invoice.id, opts
    invoice
  end

  def begin_payment(opts)
    invoice = prepare_invoice_to_pay(opts)
    logout

    payment_url = get_payment_url
    view_unpaid_invoice(payment_url, opts)
    submit_payment :created, opts
    assert_match /[1-9][0-9]* errors/, b.html, "cannot find validation error message"
    [invoice, payment_url]
  end

  def submit_payment(result_state, opts)
    opts = opts.reverse_merge(:button => 'Pay Now')
    b.button(:caption, opts[:button]).click
    b.wait
    assert_payment_state opts[:gateway], result_state
  end

  def begin_payment_with_interac
    opts = { 
      :gateway => :beanstream_interac,
      :payment_methods => [:interac],
      :button => "Pay Now Through INTERAC Online"
    }
    invoice, payment_url = begin_payment(opts)
    set_billing_address(opts)
    submit_payment :clearing, opts
    [invoice, payment_url]
  end

  def use_interac_online_emulator(opts)
    assert b.html.include? 'Interac Online Emulator'
    @user.button(:caption, "Test Bank #1").click
    b.wait
    @user.button(:caption, "Login").click
    b.wait
    if opts[:succeed]
      @user.button(:caption, 'Send Now').click
      b.wait
      tempfile = File.expand_path("/tmp/interac#{Time.now.to_f}.html")
      sleep 25
      begin
        File.open(tempfile, 'w') do |f|
          f.puts b.html
        end
        @user.goto("file://#{ tempfile }")
        @user.button(:id, 'btnNext').click
        b.wait
      ensure
        File.delete(tempfile)
      end
      #sleep 3 # wait for transaction to complete on the server.
    else
      @user.button(:caption, 'Cancel').click
    end
  end

  def assert_successfully_paid(invoice)
    invoice.reload
    assert_equal "paid", invoice.status
    assert_equal 0.0, invoice.owing_amount
    assert_equal invoice.total_amount, invoice.paid_amount
  end

  def test_typical_gateway(opts)
    invoice, payment_url = begin_payment(opts)
    set_billing_address opts
    set_credit_card opts.merge(:valid => false)
    submit_payment :error, opts
    assert b.html.include? opts[:decline_message]

    set_credit_card opts.merge(:valid => true)
    submit_payment :cleared, opts
    assert b.html.include?("successfully recorded")
    assert_successfully_paid(invoice)
    view_paid_invoice(payment_url)
    assert_payment_state opts[:gateway], :cleared
  end

end
