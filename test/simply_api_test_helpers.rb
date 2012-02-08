module SimplyApiTestHelpers
  def browsal_attributes(start_status)
    attrs = { :browsal_type => 'SendInvoiceBrowsal' }
    if start_status
      attrs[:start_status] = start_status
    end
    attrs
  end

  def simply_invoice_attributes(options={})
    options ||= {}
    invoice = {}
    invoice[:invoice_type] = "SimplyAccountingInvoice"
    invoice[:metadata] = {}
    invoice[:simply_guid] = "I0000000000111111111122222222223"
    invoice[:simply_amount_owing] = 70.0
    invoice[:date] = Date.today
    invoice[:date_due] = Date.today
    invoice[:unique] = "987654321"
    invoice[:reference] = "123456789"
    invoice[:subtotal_amount] = 100.0
    invoice[:discount_before_tax] = true
    invoice[:discount_type] = "amount"
    invoice[:discount_value] = 10.0
    invoice[:discount_amount] = 10.0
    invoice[:total_amount] = 103.50
    invoice[:currency] = "CAD"
    invoice[:description] = "Simply Invoice Description"
    invoice[:customer] = {}
    invoice[:customer][:metadata] = "{}"
    invoice[:customer][:simply_guid] = "C0000000000111111111122222222223"
    invoice[:customer][:name] = "customer name"
    invoice[:customer][:contact_name] = "contact name"
    invoice[:customer][:preferred_language] = "en"
    invoice[:taxes] = []
    invoice[:taxes][0] = {}
    invoice[:taxes][0][:name] = "Tax1"
    invoice[:taxes][0][:rate] = 10.0
    invoice[:taxes][0][:included] = true
    invoice[:taxes][0][:amount] = 9.0
    invoice[:taxes][0][:tax_on_tax] = []
    invoice[:taxes][0][:tax_on_tax][0] = {}
    invoice[:taxes][0][:tax_on_tax][0][:tax_name] = "Tax2"
    invoice[:taxes][1] = {}
    invoice[:taxes][1][:name] = "Tax2"
    invoice[:taxes][1][:rate] = 5.0
    invoice[:taxes][1][:included] = true
    invoice[:taxes][1][:amount] = 4.5
    invoice[:taxes][1][:tax_on_tax] = []
    invoice[:tax_amount] = 13.5
    invoice[:invoice_file_attributes] = {}
    invoice[:invoice_file_attributes][:content_type] = "application/pdf"
    invoice[:invoice_file_attributes][:filename] = "invoice.pdf"
    invoice[:invoice_file_attributes][:temp_data64] = <<EOD
JVBERi0xLjQNCiX/////DQo0IDAgb2JqDTw8DS9UeXBlIC9QYWdlDS9QYXJl
bnQgMyAwIFINL01lZGlhQm94IFswIDAgNjEyIDc5Ml0NL0Nyb3BCb3ggWzAg
MCA2MTIgNzkyXQ0vUmVzb3VyY2VzIDw8DS9Qcm9jU2V0IFsvUERGIC9UZXh0
IC9JbWFnZUIgL0ltYWdlQyAvSW1hZ2VJXQ0vRm9udCA8PCAvRjEgNyAwIFIg
L0YyIDkgMCBSID4+DT4+DS9Db250ZW50cyBbNSAwIFJdDT4+DWVuZG9iag01
IDAgb2JqDTw8IC9MZW5ndGggNiAwIFIgL0ZpbHRlciAvRmxhdGVEZWNvZGUg
Pj4Nc3RyZWFtDQp4Xp1X627iRhR+At7hVNVKbZV45+LxJf8CoRukLEmBpL8n
MBvcBTuyTXazT98zF98oib0VEniY+b5z5txN4dvo458UqO8RAqsvo/FqRIHg
hwKPPEYg9LnHcWs/+u1+PnuYLpaXNzC5nS9Xi/vJanY7/x1W/4ymK0MTvcnC
uUeEYaGEwTnwkFD4WxUlXMuiTNKnApZlrlQ5jI5xL7B0DzJdZ4cXlZ/BOE/K
pNjCJNsd9o+JhAcxAXYdDKNEEzB7z4lM5UZCG3baPrE1EKsMNJs/3M4m0wbI
TsuzOBp7wuHSlyxZK5hn3sVAMAkM8kqWaiAkCGMDuZNPvRA/YB7tqMjCSIiB
KKfbZ5kDp2fACB2IrFSkgzwW+KEXWu2W2W4DZdZ3rSDWgIART9jguT48ZTDx
4Ebus1wNQ1Pq+c4msFSySDYKrvLkZSCcsCrMxvK1+Ib+OxG5g6hEzG0GxJdA
F31R7sRzvysbluttlu1gnMl800PBInps923yPMDunDInvCoCffLfpWG+F1v5
P+W/Ck5Fpf7PObDCk6BKiv/vQccl4tDjro4N8mIV+RVqku33Ki37HBCboGtg
q61Mv8JrdoAvWa5/c3g8FEmqiuKXHipXLW2Kr1S+Ly6AffjIyRnMVYnW8eDq
oOCzfAX9n05+r6JMRzwASri2314/c+FFAnajJW7pj/4rwC1f+Lq+43O19649
hI+12wWWu8aQWkqpKYwCO1zoehPjvgjCKF5MCCGtMnQSXxXWQFQBsVAXcJtv
MKxR/EA0+sahTTZ1KrqxiPCJThtjsDjyAtIymAhb+3pxfKCNbx3uHLCYt/D6
uGBY9GoKu6jOEC+MGXxyv08Wg/YUPNZOEegivN85DXWFz9Vo/IeFISQdURp4
sT0ba3637mpx5HuCQuqqRkwaMRMG2oazUu3bxkcRItQKNCLs+l0RdYSwWF+1
xX+fJvWIko6YbgYt9d16GHcQGfs03H8dZFom5WvL+8wYr+Z360H8DMu0Nm3D
f6WKdZ48l0mWtkQIE72NCLseJIJj/proqEWs5PeG2qe841y3HkYdmJRuUY9l
oeAuxzmpJQHrRNv+bj1Igo9hTDuxc5UUa/jQsAvKG2q9GMYbHBtFx0xX8zeg
AsONd6CX++yQtmbiNyqJKWOkHtauccYmPaCq+DWoqVxve0CM+Ca1G1BfjWTo
c52hLeVkutkp7Bo32forDv49BJzbFG/pedcHiekRhKFL+gzix8eChqCEOL7f
EJSzio+KUtt5pnf4UvRpuYLpd7V/Ls/gDp/DOhh7eHAwiy0PwnowQkRaaAuD
1uob0G2IYVhVnfL0u6C+wQX8atoo6G9Y1AGC1o182yfwV/cJH0sNM9mq8yWE
84DqN6luj3in+Psi1jfBShG5sSYr5Q66OVMXCRQTtWpEa7aoj5jZQyd6Z/A4
aRDnd5QdOLfrptetHSiRV6WjI841WrsZmpmntWlP/2fnDUUodlsclaI6/la5
NHkFcxxEVd43BFnPNnA9hDyrDYxfhyHdu5B5A+vH2EHUYSZbdUifzmC6S37I
R1VuYSHr5vcvfeKjRQ1lbmRzdHJlYW0NZW5kb2JqDTYgMCBvYmoNMTE3Mg1l
bmRvYmoNNyAwIG9iag08PA0vVHlwZSAvRm9udA0vU3VidHlwZSAvVHJ1ZVR5
cGUNL0Jhc2VGb250IC9BcmlhbCxCb2xkDS9FbmNvZGluZyAvV2luQW5zaUVu
Y29kaW5nDS9GaXJzdENoYXIgMzINL0xhc3RDaGFyIDI1NQ0vV2lkdGhzIFsg
DTI3OCAzMzMgNDc0IDU1NiA1NTYgODg5IDcyMiAyMzggMzMzIDMzMyAzODkg
NTg0IDI3OCAzMzMgMjc4IDI3OCA1NTYgNTU2IDU1NiA1NTYgNTU2IDU1NiA1
NTYgNTU2IDU1NiA1NTYgMzMzIDMzMyA1ODQgNTg0IDU4NCA2MTENOTc1IDcy
MiA3MjIgNzIyIDcyMiA2NjcgNjExIDc3OCA3MjIgMjc4IDU1NiA3MjIgNjEx
IDgzMyA3MjIgNzc4IDY2NyA3NzggNzIyIDY2NyA2MTEgNzIyIDY2NyA5NDQg
NjY3IDY2NyA2MTEgMzMzIDI3OCAzMzMgNTg0IDU1Ng0zMzMgNTU2IDYxMSA1
NTYgNjExIDU1NiAzMzMgNjExIDYxMSAyNzggMjc4IDU1NiAyNzggODg5IDYx
MSA2MTEgNjExIDYxMSAzODkgNTU2IDMzMyA2MTEgNTU2IDc3OCA1NTYgNTU2
IDUwMCAzODkgMjgwIDM4OSA1ODQgNDAwDTQwMCA0MDAgNDAwIDQwMCA0MDAg
NDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0
MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQw
MCA0MDAgNDAwIDQwMCA0MDANMjc4IDMzMyA1NTYgNTU2IDU1NiA1NTYgMjgw
IDU1NiAzMzMgNzM3IDM3MCA1NTYgNTg0IDMzMyA3MzcgNTUyIDQwMCA1NDkg
MzMzIDMzMyAzMzMgNTc2IDU1NiAyNzggMzMzIDMzMyAzNjUgNTU2IDgzNCA4
MzQgODM0IDYxMQ03MjIgNzIyIDcyMiA3MjIgNzIyIDcyMiAxMDAwIDcyMiA2
NjcgNjY3IDY2NyA2NjcgMjc4IDI3OCAyNzggMjc4IDcyMiA3MjIgNzc4IDc3
OCA3NzggNzc4IDc3OCA1ODQgNzc4IDcyMiA3MjIgNzIyIDcyMiA2NjcgNjY3
IDYxMQ01NTYgNTU2IDU1NiA1NTYgNTU2IDU1NiA4ODkgNTU2IDU1NiA1NTYg
NTU2IDU1NiAyNzggMjc4IDI3OCAyNzggNjExIDYxMSA2MTEgNjExIDYxMSA2
MTEgNjExIDU0OSA2MTEgNjExIDYxMSA2MTEgNjExIDU1NiA2MTEgNTU2IF0N
L0ZvbnREZXNjcmlwdG9yIDggMCBSDT4+DWVuZG9iag04IDAgb2JqDTw8DS9U
eXBlIC9Gb250RGVzY3JpcHRvcg0vRm9udE5hbWUgL0FyaWFsLEJvbGQNL0Zs
YWdzIDMyDS9Gb250QkJveCBbIC02MjggLTM3NiAyMDAwIDEwMTAgXQ0vQXZn
V2lkdGggNDc5DS9TdGVtViAwDS9DYXBIZWlnaHQgMA0vSXRhbGljQW5nbGUg
MA0vQXNjZW50IDkwNQ0vRGVzY2VudCAyMTINPj4NZW5kb2JqDTkgMCBvYmoN
PDwNL1R5cGUgL0ZvbnQNL1N1YnR5cGUgL1RydWVUeXBlDS9CYXNlRm9udCAv
QXJpYWwNL0VuY29kaW5nIC9XaW5BbnNpRW5jb2RpbmcNL0ZpcnN0Q2hhciAz
Mg0vTGFzdENoYXIgMjU1DS9XaWR0aHMgWyANMjc4IDI3OCAzNTUgNTU2IDU1
NiA4ODkgNjY3IDE5MSAzMzMgMzMzIDM4OSA1ODQgMjc4IDMzMyAyNzggMjc4
IDU1NiA1NTYgNTU2IDU1NiA1NTYgNTU2IDU1NiA1NTYgNTU2IDU1NiAyNzgg
Mjc4IDU4NCA1ODQgNTg0IDU1Ng0xMDE1IDY2NyA2NjcgNzIyIDcyMiA2Njcg
NjExIDc3OCA3MjIgMjc4IDUwMCA2NjcgNTU2IDgzMyA3MjIgNzc4IDY2NyA3
NzggNzIyIDY2NyA2MTEgNzIyIDY2NyA5NDQgNjY3IDY2NyA2MTEgMjc4IDI3
OCAyNzggNDY5IDU1Ng0zMzMgNTU2IDU1NiA1MDAgNTU2IDU1NiAyNzggNTU2
IDU1NiAyMjIgMjIyIDUwMCAyMjIgODMzIDU1NiA1NTYgNTU2IDU1NiAzMzMg
NTAwIDI3OCA1NTYgNTAwIDcyMiA1MDAgNTAwIDUwMCAzMzQgMjYwIDMzNCA1
ODQgNDAwDTQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQw
MCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAw
IDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAgNDAwIDQwMCA0MDAN
Mjc4IDMzMyA1NTYgNTU2IDU1NiA1NTYgMjYwIDU1NiAzMzMgNzM3IDM3MCA1
NTYgNTg0IDMzMyA3MzcgNTUyIDQwMCA1NDkgMzMzIDMzMyAzMzMgNTc2IDUz
NyAyNzggMzMzIDMzMyAzNjUgNTU2IDgzNCA4MzQgODM0IDYxMQ02NjcgNjY3
IDY2NyA2NjcgNjY3IDY2NyAxMDAwIDcyMiA2NjcgNjY3IDY2NyA2NjcgMjc4
IDI3OCAyNzggMjc4IDcyMiA3MjIgNzc4IDc3OCA3NzggNzc4IDc3OCA1ODQg
Nzc4IDcyMiA3MjIgNzIyIDcyMiA2NjcgNjY3IDYxMQ01NTYgNTU2IDU1NiA1
NTYgNTU2IDU1NiA4ODkgNTAwIDU1NiA1NTYgNTU2IDU1NiAyNzggMjc4IDI3
OCAyNzggNTU2IDU1NiA1NTYgNTU2IDU1NiA1NTYgNTU2IDU0OSA2MTEgNTU2
IDU1NiA1NTYgNTU2IDUwMCA1NTYgNTAwIF0NL0ZvbnREZXNjcmlwdG9yIDEw
IDAgUg0+Pg1lbmRvYmoNMTAgMCBvYmoNPDwNL1R5cGUgL0ZvbnREZXNjcmlw
dG9yDS9Gb250TmFtZSAvQXJpYWwNL0ZsYWdzIDMyDS9Gb250QkJveCBbIC02
NjUgLTMyNSAyMDAwIDEwMDYgXQ0vQXZnV2lkdGggNDQxDS9TdGVtViAwDS9D
YXBIZWlnaHQgMA0vSXRhbGljQW5nbGUgMA0vQXNjZW50IDkwNQ0vRGVzY2Vu
dCAyMTINPj4NZW5kb2JqDTExIDAgb2JqDTw8DS9UeXBlIC9DYXRhbG9nDS9Q
YWdlcyAzIDAgUg0+Pg1lbmRvYmoNMiAwIG9iag08PA0vUHJvZHVjZXIgKEFt
eXVuaSBQREYgQ3JlYXRvciAyLjAxLWQpDS9DcmVhdG9yIChBbXl1bmkgUERG
IENyZWF0b3IpDT4+DWVuZG9iag0zIDAgb2JqDTw8DS9UeXBlIC9QYWdlcw0v
Q291bnQgMQ0vUm90YXRlIDANL0tpZHMgWzQgMCBSIF0NPj4NZW5kb2JqDXhy
ZWYNMCAxMg0wMDAwMDAwMDAwIDY1NTM1IGYgDTAwMDAwMDAwMDAgMDAwMDAg
biANMDAwMDAwNDAyNiAwMDAwMCBuIA0wMDAwMDA0MTE1IDAwMDAwIG4gDTAw
MDAwMDAwMTcgMDAwMDAgbiANMDAwMDAwMDIyNCAwMDAwMCBuIA0wMDAwMDAx
NDcxIDAwMDAwIG4gDTAwMDAwMDE0OTEgMDAwMDAgbiANMDAwMDAwMjU1MiAw
MDAwMCBuIA0wMDAwMDAyNzM3IDAwMDAwIG4gDTAwMDAwMDM3OTUgMDAwMDAg
biANMDAwMDAwMzk3NiAwMDAwMCBuIA10cmFpbGVyDTw8DS9TaXplIDEyDS9S
b290IDExIDAgUg0vSW5mbyAyIDAgUg0vSUQgWzw2MDA3ODkzQzI5OUY3MjRD
QjFEMDA4RjgzODQxQTYzRD48NjAwNzg5M0MyOTlGNzI0Q0IxRDAwOEY4Mzg0
MUE2M0Q+XQ0+Pg1zdGFydHhyZWYNNDE4Mw0lJUVPRg0=
EOD
    invoice.merge(options)
  end
  
  def simply_delivery_attributes(options={})
    options ||= {}
    delivery = {}
    delivery[:reply_to] = "simply_accounting_user@billingboss.com"
    delivery[:recipients] = "test@test.com"
    delivery[:subject] = "the delivery subject"
    delivery[:body] = "the delivery body"
    delivery.merge(options)
  end

  def browsal_request(mode, start_status, authorized = nil, options = {})
    api_token = nil
    current_url = nil
    token_url = nil

    auth = nil
    if authorized == :authorized
      auth = { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('basic_user@billingboss.com', 'test') }
    elsif authorized
      auth = { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('brand_new_user@billingboss.com', 'test') }
    end
    attributes = nil
    if mode == :send_invoice
      attributes = { :simply_request => {
          :browsal => browsal_attributes(start_status),
          :invoice => simply_invoice_attributes(options[:invoice]),
          :delivery => simply_delivery_attributes,
          :user_gateway => options[:user_gateway]
        }, :format => 'xml' }
    elsif mode == :signup
      attributes = { :simply_request => {
          :user => { :login => 'basic_user@billingboss.com' },
          :browsal => { :browsal_type => 'SignupBrowsal', :start_status => start_status },
        }, :format => 'xml' }
    end
    extended_session do |api|
      api.post('/browsals', attributes, auth)
      api_token = ApiToken.last
      token_url = api.response.headers['Location']
      current_url = api.current_url
      unless start_status.to_s == 'login'
        stub_cas_logged_in(users(:basic_user)) if authorized == :authorized
      end
      yield api, api_token, current_url, token_url if block_given?
    end
    [api_token, current_url, token_url]
  end

  def initiate_signup(start_status, authorized = nil)
    result = nil
    assert_difference('ApiToken.count') do
      result = browsal_request(:signup, start_status, :authorized) do |api, api_token, current_url, token_url|
        if api.response.code != '201'
          puts api.response.body
        end
        api.assert_response :created 
        if start_status
          assert_match %r{^http://[^/]*/browsals/#{ api_token.guid }/#{ start_status }$}, current_url
        end
      end
    end
    result
  end

  # Make sure the test class that calls this also includes SimplyApiTestHelpers
  def initiate_send_invoice(start_status, authorized = nil, options = {})
    result = nil
    assert_difference('ApiToken.count') do
      result = browsal_request(:send_invoice, start_status, authorized, options) do |api, api_token, current_url, token_url|
        if api.response.code != '201'
          puts api.response.body
        end
        api.assert_response :created 
        case start_status
        when nil, 'login', 'send_invoice'
          assert_match %r{^http://[^/]*/browsals/#{ api_token.guid }/send_invoice$}, current_url
        else
          assert_match %r{^http://[^/]*/browsals/#{ api_token.guid }/#{ start_status }$}, current_url
        end
      end
    end
    result
  end
  
  def session_successfully_create_user(api_token, current_url)
    extended_session do |user|
      user.signup_page!(current_url)
      user.signup!
      user.assert_response :success
      user.assert_template 'users/simply/thankyou'
      yield user
    end
  end

  def session_successfully_login(api_token, current_url, expected_dest = nil, email = nil)
    unstub_cas
    extended_session do |user|
      which_user = email.nil? ? users(:basic_user) : User.find_by_email(email)
      user.simulate_login!(current_url, which_user)
      user.get current_url
      if expected_dest.nil? or expected_dest == :new_delivery
        user.redirect_to_new_delivery!
      elsif expected_dest == :switch_to_sps
        user.redirect_to_switch_to_sps!
      else
        fail 'unknown expected dest'
      end
      yield user
    end
  end
end
