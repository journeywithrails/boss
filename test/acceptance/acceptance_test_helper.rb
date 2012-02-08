require 'test/unit'
require 'fileutils'
require 'ftools'
require 'net/pop'
require 'highline'

$test_ui = HighLine.new

require File.dirname(__FILE__) + '/acceptance_test_urls'
require File.dirname(__FILE__) + '/browser_switch'

Sage::Test::Server.configure

$paypal_hidden = true
  

  class Test::Unit::TestCase
    #include helpers for Acts as Authenticated plugin
    self.use_transactional_fixtures = false
  end  

  
  #assumgin an instance of the server is running in test environment
  class SageTestSession
    attr_accessor :b, :username, :user
    attr_accessor :port, :host
    attr_accessor :current_paypal_payer_id, :current_paypal_token, :current_access_key
    attr_writer :active_merchant_live

    include AcceptanceTestUrls
    
    @@test_class_browser_instance = nil
    
    def with(name)
      @username = name
      @user = @test_case.users(name)
      self
    end
    
    def with_sage_user(name_or_attrs)
      case name_or_attrs
      when String, Symbol
        test_dir = File.dirname(File.dirname(__FILE__))
        sage_users_file = File.join(test_dir, 'fixtures', 'config', 'sso_integration', 'sage_users.yml')
        sage_users = YAML.load_file sage_users_file
        sage_user = sage_users[name_or_attrs.to_s]
        @user = OpenStruct.new(sage_user)
      when Hash
        @user = OpenStruct.new(name_or_attrs)
      when OpenStruct
        @user = name_or_attrs
      end      
      @username = @user.username
      self
    end
    
    # use this in sso-integration tests
    def with_username(name)
      @username = name
      self
    end
    
    def self.create_browser()
      @b = ::WatirBrowser.get_browser
    end
  
    def initialize(test_case, options={})
      @test_case = test_case
      # can be set by script to allow the tests to reuse the same browser
      if ($external_browser_instance.nil?)
        @b = SageTestSession::create_browser
      else
        @b = $external_browser_instance        
      end
      
      Sage::Test::Server.billingboss.ensure if Sage::Test::Server.has_billingboss?
      
      @@test_class_browser_instance = @b
      
      @port = options[:port] || ENV['TORNADO_TEST_SERVER_PORT'] || SageTestSession.default_port
      @host = options[:host] || ENV['TORNADO_TEST_SERVER_SERVER'] || SageTestSession.default_host
    end
    
    def self.default_port
      Sage::Test::Server.billingboss.port
    end
    
    def self.default_host
      Sage::Test::Server.billingboss.host
    end
             
    def site_url
      (@port.blank? || @port == '80') ? "http://#{@host}" : "http://#{@host}:#{@port}"
    end

    
    def email_server
      "billingboss.com"
    end
    
    def autotest_email
      "autotest@10.152.17.65"
    end
    
    def admin_email
      "admin@" + email_server
    end

    # recalculate invoices because fixtures do not necessarily have correct XXXXX_amount
    def recalc_invoices
      goto site_url + "/admin/dashboard/recalc"
    end
    
    def wait_for_delivery_of(deliverable_id, msg = "while waiting for delivery", wait_time=60)
      current_id = Delivery.maximum(:id)
      yield
      delivery = nil
      begin
        Watir::Waiter.new(wait_time, 1).wait_until do
          begin
            delivery = Delivery.find(:first, :conditions => ["id > ? AND deliverable_id = ?" , current_id, deliverable_id])
            if delivery.nil?
              false
            elsif delivery.message_id.nil?
              false
            else
              true
            end
          end
        end
      rescue Watir::Exception::TimeOutException => e
        if delivery.nil?
          @test_case.flunk "#{msg}: No delivery was created after #{wait_time} seconds"
        else
          @test_case.flunk "#{msg}: A delivery was created but not delivered after #{wait_time} seconds"
        end
      end
      delivery.nil? ? nil : delivery.message_id # in theory delivery can never be nil here
    end
    
    def wait_for_access_key_to_be_created(keyable_id, msg, wait_time=30)
      current_id = AccessKey.maximum(:id)
      yield
      ak = nil
      begin
        Watir::Waiter.new(wait_time, 1).wait_until do
          begin
            ak = AccessKey.find(:first, :conditions => ["id > ? AND keyable_id = ?" , current_id, keyable_id])
            !ak.nil?
          end
        end
      rescue Watir::Exception::TimeOutException => e
        puts e.inspect
        @test_case.flunk "#{msg}: No access key was created after #{wait_time} seconds"
      end
      ak.nil? ? nil : ak.key
    end
    
    def direct_payment_url
    end
    
    def stub_logged_in(name=nil)
      @username ||= name
      @username ||= :basic_user
      @user ||= @test_case.users(@username)
      @b.goto(stub_logged_in_with_cas_url + @user.id.to_s)
      @test_case.assert @b.contains_text(user.sage_username + " logged in test mode")
    end

    def logs_in(name=nil)
      stub_logged_in(name)
    end
    
    def stub_first_login(username, email)
      username = CGI::escape(username)
      email = CGI::escape(email)
      @b.goto("#{stub_first_login_url}?pending_sage_user=#{username}&pending_sage_user_email=#{email}")
    end
    
    def stub_gateway
      @b.goto(stub_gateway_url)
      @test_case.assert @b.contains_text("logged out with stubbed cas gateway")
    end

    def is_new_user
      stub_gateway
    end
    
    def is_logged_out
      stub_gateway
    end

    def stub_logged_out
      @b.goto(stub_logged_out_with_cas_url)
      @test_case.assert @b.contains_text("logged out & cas unstubbed")
    end

    def logs_out
      stub_logged_out
    end

    def logs_out_cas
      # @debug=true
      url = Sage::Test::Server.sagebusinessbuilder.url + "/caslogout"
      @b.goto(url)
      exit unless $test_ui.agree('logged out. continue?', true) if @debug
      # @test_case.assert @b.contains_text("Logout successful")
    end

    def logs_out_cas_from_cas
      url = Sage::Test::Server.cas_server_sage.url + "/logout"
      @b.goto(url)
      exit unless $test_ui.agree('logged out. continue?', true) if @debug
    end
    
    def creates_new_invoice
      @b.goto(site_url + "/invoices/new")
      self
    end
    
    def shows_invoice(id)
      @b.goto(site_url + "/invoices/#{id}")
      self
    end
    
    def edits_invoice(id)
      @b.goto(site_url + "/invoices/#{id}/edit")
      self
    end

    def shows_invoice(id)
      @b.goto(site_url + "/invoices/#{id}")
      self
    end
    
    def removes_invoice(id)
      @b.goto(site_url + "/invoices/destroy/#{id}")
    end
    
    def displays_invoice_list()
      puts "displays_invoice_list" if $log_on 
      @b.goto(site_url + "/invoices/")
      self
    end
    
    def displays_invoice_overview()
      puts "displays_invoice_overview" if $log_on 
      @b.goto(site_url + "/invoices/overview/")
      self
    end
    
    def displays_customer_overview()
      @b.goto(site_url + "/customers/overview/")
      self
    end
    
    def submits
      @b.button(:name, "commit").click
      self
    end

    def cancels
      @b.link(:id, "cancel").click
      self
    end

    # redirect any methods starting with 'and_ ' to their non-'and' equivalents

    #Add a new line item to the invoice.
    #optional: pass in a list of properties, one for each field in the following form:
    # :name => 'short name', :description => 'line description'
    #returns index of line item in the web page.
    #NOTE: the index is not necessarily the same as the line number after
    #lines have been deleted.
    def adds_line_item(fields)
      @b.link(:id, "add_line_item").click
      @b.wait()
      
      trows = line_items_rows
      index = trows.length
      edits_line_item(index, fields)
      index
    end
    
#    def edits_line_item(index, fields)
#      trows = @b.line_items_rows
#      tr = trows[index]
#      fields.each_pair do |field, value|
#        e = tr.text_field(:name, "invoice[line_items_attributes][][#{field.to_s}]")
#        @test_case.assert e.exists?, "tried to set an invalid field #{field.to_s}"
#        e.set(value) 
#        @b.wait()
#      end
#      self
#    end

    def edits_line_item(index, fields)
      trows = self.line_items_rows
      tr = trows[::WatirBrowser.item_index(index)]
      fields.each_pair do |field, value|
        # exit unless $test_ui.agree('continue?', true) if $debug
        # debugger
        unless (field == :unit) #unit has been deprecated, test compatibility
          e = tr.text_field(:name, "invoice[line_items_attributes][][#{field.to_s}]")
          @test_case.assert e.exists?, "tried to set an invalid field #{field.to_s}"
          
          case field.to_s
            when 'quantity', 'price'
              expects_ajax(1) do
                populate(e, value.to_s)
                #e.set(value)
              end
            else
              populate(e, value.to_s)
              #e.set(value)
          end        
        end
      end
      self
    end

    
    def gets_line_item_at(index, field)
      trows = line_items_rows
      tr = trows[::WatirBrowser.item_index(index)]
      e = tr.text_field(:name, "invoice[line_items_attributes][][#{field.to_s}]")
      
      if not e.exists?
        e = tr.span(:name, field.to_s)
        @test_case.assert e.exists?, "tried to get an invalid field #{field.to_s}"
        e.text
      else
        e.value
      end
    end

    #Removes a line item from the invoice.
    #NOTE: the index is not necessarily the same as the line number after
    #lines have been deleted.
    def removes_line_item(index)
      index = ::WatirBrowser.item_index(index)
      trows = line_items_rows
      tr = trows[index]

      @test_case.assert tr.exists? && tr.visible?, 'tried to remove a non-existent line_item.'
      expects_ajax() do
        tr.link(:name, 'remove').click
        b.wait()
      end
      self
    end
    
    def teardown
      logs_out
      # @b.close if ($external_browser_instance.nil?)
      @b.goto('about:blank')
      # else
      #   # if browser is started by external program, do not close it assuming external code will manage its lifespan
      #   @b.goto(logoff_url)
      # end        
      # sleep 3
      
      
       # At least ten times, running acceptance tests through CruiseControl
       # on INNOV-BUILD resulted in 50 open IE windows!  Don't care to find out why,
       # as this is the only computer where this happens.
       if ENV['COMPUTERNAME'] == 'INNOV-BUILD'
         `taskkill /f /im iexplore.exe`
       end
       
    end
    
    # Set generic invoice fields. Each field is optional. Use it as follows:
    # @basic_user.creates_new_invoice
    # @basic_user.sets_invoice(:unique => "INV-TEST", :description => "New Invoice", :date => "4/28/2005", :reference =>"44112")
    def sets_invoice(fields)
      fields.each_pair do |field, value|
        e = @b.text_field(:id, "invoice_#{field.to_s}")
        @test_case.assert e.exists?, "tried to set an invalid invoice field #{field.to_s}"
        e.value=(value)
        @b.wait()
      end
      self
    end
    
    def line_items_rows
      @b.table(:id, "line_items_table").bodies[::WatirBrowser.first_item].rows
    end
    
    def entity_list_rows
      @b.table(:class, "entity-list").bodies[::WatirBrowser.first_item].rows
    end
    
    # Set invoice profile fields. Each field is optional. Use it as follows:
    # @basic_user.creates_new_invoice
    # @basic_user.sets_invoice_profile(
    #   :name => "modified profile name",
    #   :address1 => "modified profile address1",
    #   :address2 => "modified profile address2",
    #   :city => "modified profile city",
    #   :state => "modified profile state",
    #   :country => "modified profile country",
    #   :phone => "modified profile phone",
    #   :fax => "modified profile fax"
    #  )
    def sets_invoice_profile(fields)
      fields.each_pair do |field, value|
        e = @b.text_field(:id, "invoice_profile_attributes_#{field.to_s}")
        @test_case.assert e.exists?, "tried to set an invalid invoice profile field #{field.to_s}"
        e.value=(value)
        @b.wait()
      end
      self
    end
    

    
    # Set invoice info fields. Each field is optional. Use it as follows:
    # @basic_user.creates_new_invoice
    #@basic_user.sets_invoice_info(
    #  :unique => "Inv-0001",
    #  :date => "2007-12-15",
    #  :reference => "Ref-0001",
    #  :description => "Original description for this Invoice"
    #)    
    def sets_invoice_info(fields)
      fields.each_pair do |field, value|
        e = @b.text_field(:id, "invoice_#{field.to_s}")
        @test_case.assert e.exists?, "tried to set an invalid invoice info field #{field.to_s}"
        e.value=(value)
        @b.wait()
      end
      self    
    end    

    # Set invoice contact fields. Each field is optional. Use it as follows:
    # @basic_user.creates_new_invoice
    #user.sets_invoice_contact(
    #    :first_name => "My Contact First Name",
    #    :last_name => "My Contact Last Name",
    #    :email => "abc@address.com"
    #)
    #def sets_invoice_contact(fields)
    #  fields.each_pair do |field, value|
    #    e = @b.text_field(:id, "invoice_customer_attributes__contacts_attributes__#{field.to_s}")
    #    @test_case.assert e.exists?, "tried to set an invalid invoice info field #{field.to_s}"
    #    e.value=(value)
    #    @b.wait()
    #  end
    #  self    
    #end        
        
    def filters_by_number(unique)
      @b.text_field(:id, "filters_unique").value=(unique)
      @b.wait
      @b.button(:name, "commit").click
      @b.wait
      self
    end
    
    def expects_ajax(num=1, original_counter=nil)
      # pass in original_counter = 0 when doing a page load that calls ajax while loading, with no block
      original_counter ||= @b.div(:id, 'ajax_counter').text.to_i
      yield if block_given?
      begin
        current_counter = 0
        Watir::Waiter.new(12).wait_until do
          current_counter = @b.div(:id, 'ajax_counter').text.to_i
          
          if (current_counter - num) == original_counter
            true
          elsif (current_counter - num) < original_counter
            false
          else
            #RADAR this will never happen unless it is in between polls. oh well.
            @test_case.flunk "expected #{num} ajax requests but got #{current_counter - original_counter}"
          end
        end
      rescue Watir::Exception::TimeOutException => e
        @test_case.flunk "#{e.class.name}\n#{e.message}\nexpected #{num} ajax requests but got #{current_counter - original_counter}"
      end
    end
    
    def with_paypal_sandbox_retry
      $paypal_sandbox_retries ||= 0
      
      yield
      @b.wait
      while @b.contains_text('Please click Retry or try again later') and ($paypal_sandbox_retries < 10)
        puts "retrying sandbox..."
        sleep 1
        @b.link(:url, 'https://www.sandbox.paypal.com/us/cgi-bin/webscr?cmd=#').click
        @b.wait
        sleep 1
        begin
          startClicker(@b, 'Retry')
        rescue
        end
        $paypal_sandbox_retries += 1
      end
      @test_case.flunk "paypal sandbox is down" if $paypal_sandbox_retries > 10
    end
    
    def creates_new_payment_for_invoice(id)
      @b.goto(site_url + "/invoices/#{id}/payments/new")
      self
    end

    def displays_payments_for_invoice(id)
      @b.goto(site_url + "/invoices/#{id}/payments)")
      self
    end

    def creates_new_payment
      @b.goto(site_url + "/payments/new")
      self
    end
    
    def edits_payment(id)
      @b.goto(site_url + "/payments/#{id}/edit")
      self
    end
    
    def removes_payment(id)
      @b.goto(site_url + "/payments/destroy/#{id}")
    end
    
    def shows_payment(id)
      @b.goto(site_url + "/payments/#{id}")
      self
    end
    
    def displays_payment_list
      @b.goto(site_url + "/payments/")
      self
    end

    #TODO: refactor set_invoice, set_payment, set_* into something better.
    def sets_payment(fields)
      fields.each_pair do |field, value|
        if (field == :customer_id || field == :pay_type)
          e = @b.select_list(:id, "payment_#{field.to_s}") #dropdown list
          @test_case.assert e.exists?, "tried to set an invalid payment field #{field.to_s}"
          @test_case.assert e.includes?(value), "tried to set payment dropdown #{field.to_s} to invalid value #{value.to_s}"
          e.select(value)
        else
          e = @b.text_field(:id, "payment_#{field.to_s}")
          @test_case.assert e.exists?, "tried to set an invalid payment field #{field.to_s}"
          e.value=(value)
        end
      end
      self
    end

    def displays_customer_list
      @b.goto(site_url + "/customers/")
      self
    end
	
    def creates_new_customer
      @b.goto(new_customer_url)
      self
    end

    def destroy_sage_user(sage_username)
      Sage::Test::Server.sageaccountmanager.rest_delete("sage_users/#{sage_username}")
    end
    
    def enter_new_customer(fields)
      click_new_customer_button
      wait_until_exists('customer_name')
      # exit unless $test_ui.agree("enter_customer_data?", true)
      enter_customer_data(fields)
      # 2nd ajax call is made to display the new customer data 
      # on the invoice form
      expects_ajax(2) do
        @b.element_by_xpath("id('customer-dialog-add-button')").click # don't ask for button directly, because on firefox ext wraps button in a table, and the table gets the id not the button element
      end
    end
    
    ################### billing ############
    
    def login_to_paypal_sandbox
      goto 'https://developer.paypal.com'
      return if link(:text, 'Log Out').exists?
      text_field(:id, 'login_email').value=(@test_case.paypal_test_api_developer_account)
      text_field(:id, 'login_password').value=(@test_case.paypal_test_api_developer_password)
      with_paypal_sandbox_retry do
        button(:name, "submit").click
      end
    end
    
    def logs_in_to_paypal_buyer_account
      with_paypal_sandbox_retry do
        Watir::Waiter.new(20).wait_until do
          text_field(:id, 'login_email').exists?
        end
      end
      text_field(:id, 'login_email').value=(@test_case.paypal_test_api_buyer_account)
      text_field(:id, 'login_password').value=(@test_case.paypal_test_api_buyer_password)
      with_paypal_sandbox_retry do
        button(:id, "login.x").click
      end
    end
    
    def confirms_payment_in_paypal
      with_paypal_sandbox_retry do
        button(:id, "continue").click
      end
    end
    
    def cancels_payment_in_paypal
      with_paypal_sandbox_retry do
        link(:text, /Test Store/).click
      end
    end
    
    def cancels_payment
      button(:id, "cancel").click
    end
    
    def clicks_on_direct_payment
      stub_out_gateway(@test_case.successful_setup_purchase_response) unless active_merchant_live?

      #url = @test_case.direct_payment_url(:gateway => 'paypal_express', :access => @current_access_key)
      url = site_url + "/payments/paypal_express/#{@current_access_key}/direct"
      with_paypal_sandbox_retry do
        goto url
      end
#      @current_paypal_token = hidden(:id, 'token').value
      Watir::Waiter.new(120).wait_until do
        button(:id, "login.x").exists?
      end
    end

    def returns_from_paypal
      stub_out_gateway(@test_case.successful_details_response(@current_paypal_token)) unless active_merchant_live?
      @current_paypal_payer_id = 'TEST'
      url = direct_payment_confirm_url(:access => @current_access_key, :gateway => 'paypal_express', :token => current_paypal_token, :PayerID => 'TEST')
      get url
      assert_template 'payments/confirm'
    end

    def confirms_order
      stub_out_gateway(@test_case.successful_authorization_response(@current_paypal_token)) unless active_merchant_live?
      url = direct_payment_complete_url(:access => @current_access_key, :gateway => 'paypal_express', :token => @current_paypal_token, :PayerID => current_paypal_payer_id)
      get url
      assert_template 'payments/complete'
    end

    def stub_out_gateway(response)
#      ActiveMerchant::Billing::PaypalExpressGateway.any_instance.expects(:ssl_post).returns(response)
    end

    def active_merchant_live?
#      @active_merchant_live
      true
    end
    ################### end billing ############

    
    def method_missing(method, *args, &block)
      str = method.id2name
      str2 = str.sub(/^and_/, '')
      if (str2 != str)
        return self.send(str2.to_sym, *args, &block) if self.respond_to?(str2.to_sym)      
      end

      str2 = str.sub(/^goto_/, '')
      if (str2 != str)
        return self.b.goto(send(str2.to_sym, *args)) if self.respond_to?(str2.to_sym)      
      end
      return self.b.send(method, *args, &block)
    end
    
    
    ######### custom assertions ############
    def assert_flash(target, msg)
      @test_case.assert self.b.div(:id, 'flash_message').exists?, msg + "but page has no flash message div"
      msg += "but the flash message did not match #{target.to_s}"
      if target.kind_of? Regexp
        @test_case.assert self.b.div(:id, 'flash_message').text.match(target), msg
      elsif target.kind_of? String
        @test_case.assert self.b.div(:id, 'flash_message').text.index(target), msg
      else
        @test_case.flunk "don't understand how to match flash message with a #{target.class.name}"
      end
    end    
    
    def assert_on_page(path, msg)
      path = '/' + path unless path[0...1] == '/'
      @test_case.assert_match(/#{self.site_url}#{path}/, self.b.url, msg)
      if self.b.div(:id, "Full-Trace").exists?
        @test_case.flunk("while checking #{msg}: #{path} had exception\n#{self.b.div(:id, "Full-Trace").text}")
      end
    end

    def assert_on_cas_page(path, msg)
      path = '/' + path unless path[0...1] == '/'
      path = Sage::Test::Server.cas_server_sage.url + path
      @test_case.assert_match(/#{path}/, self.b.url, msg)
      if self.b.div(:id, "Full-Trace").exists?
        @test_case.flunk("while checking #{msg}: #{path} had exception\n#{self.b.div(:id, "Full-Trace").text}")
      end
    end

    def assert_home
      assert_on_page('/', 'not on home page')
      @test_case.assert self.b.text.include?("No more messy spreadsheets"), "expected home page (No more messy spreadsheets) but found:\n#{self.b.text}"
    end

    def assert_user_owns_page(key)
      if key.is_a?(Symbol)
        username = @test_case.users(key).sage_username
      else
        username = key
      end
      @test_case.assert self.b.text.include?("Logout (#{username})"), "Profile page should include logout link for #{username.to_s} but found: #{self.b.text}"
    end

    def click_new_customer_button()
      b.button(:id, "new-btn").click
    end

    def click_customer_add_button(ajax_calls=2)
      # 2nd ajax call is made to display the new customer data 
      # on the invoice form
      expects_ajax(ajax_calls) do
        b.element_by_xpath("id('customer-dialog-add-button')").click
      end
    end

    def enter_customer_data(fields)
      wait_until_exists('customer_country')
      fields.each_pair do |field, value|
        field_name = "customer_#{field.to_s}"
        
        case field.to_s
        # country is a  select
        when 'country' then
          #if trying to select already selected item, ajax call will fail
          unless (select_list(:id, "customer_country").getSelectedItems[0] == value)
            expects_ajax(2) do
              b.select_list(:id, field_name).select(value)          
            end
          end
        when 'province_state' then
          # province_state is a select for known countries 
          # and a textbox for unknown countries
          # the type of a textbox is 'type', select is select-one
          case b.select_list(:id, field_name).type
          when "text" then
            b.text_field(:id, field_name).value=(value)
          when "select-one" then
            b.select_list(:id, field_name).select(value)
          end
        else
          exit unless $test_ui.agree("about to set #{field_name}. continue?", true) if @debug || $debug
          b.text_field(:id, field_name).value=(value)
        end
      end

    end

    def select_customer(user, customer_name)
      user.expects_ajax(1) do
        b.select_list(:id, "invoice_customer_id").select(customer_name)          
      end
    end

    def select_customer_at_index(index)
      customer_select = b.select_list(:id, "invoice_customer_id")
      customer_array = customer_select.getAllContents()
      unless index == 0
        customer_at_index = customer_array[index]
        unless customer_at_index.nil?
          customer_select.select(customer_at_index.to_s)            
        end
      end
    end


    def fills_in_form_from_hash(values, options={})
      form = (options[:form_id] ? @b.form(:id, options[:form_id]) : @b.forms[0])
      @test_case.assert form.exists?, "couldn't find a form (id=#{options[:form_id]})"
      prefix = options[:prefix] || ""
      suffix = options[:suffix] || ""

      values.each do |k,v|
        selector = options[:by_name] ? :name : :id
        k = (prefix + k.to_s + suffix) unless k.is_a?(Regexp)
        fields = [@b.text_field(selector, k), @b.select_list(selector, k)]
        @test_case.assert(fields.detect{|f| f.exists?}, "couldn't find a field matching #{k}") if(options[:assert_keys])
        fields.each do |f|
          f.value=(v.to_s) if f.exists?
        end
      end
    end

    # WARN: don't know why but sometimes elements by xpath exist slightly before
    # element addressed by, for example, select_list(:id, ...) exist
    def wait_until_exists(element_id=nil, wait_time=12, msg="wait_until_exists", &block)
      wait_until_predicate(:exists?, element_id, wait_time, msg, &block)
    end
    
    
    def wait_until_no_longer_exists(element_id, wait_time=4, msg="wait_until_no_longer_exists")
      p = Proc.new {|e| not e.exists? }
      wait_until_predicate(p, element_id, wait_time, msg, &block)
    end
    
    
    def wait_until_predicate(predicate, element_id=nil, wait_time=4, msg=nil)
      if predicate.kind_of?(Symbol)
        msg ||= "wait_until_predicate(#{predicate.to_sym})"
      else
        msg ||= "wait_until_predicate"
      end
        
      if block_given?
        begin
          Watir::Waiter.new(wait_time, 1).wait_until do
            yield
          end
        rescue Watir::Exception::TimeOutException => e
          @test_case.flunk "#{msg}: #{element_id} did not occur after #{wait_time} seconds"
        end
      else
        wait_until_predicate_xpath(predicate, "id('#{element_id}')", wait_time, msg)
      end
    end
    
    
    def wait_until_predicate_xpath(predicate, xpath, wait_time=4, msg="wait_until_exists")
      xpath = [xpath].flatten
      begin
        Watir::Waiter.new(wait_time, 1).wait_until do
          if predicate.kind_of?(Symbol)
            xpath.all?{|an_xpath| b.element_by_xpath(an_xpath).send(predicate)}
          elsif predicate.kind_of?(Proc)
            xpath.all?{|an_xpath| predicate.call(b.element_by_xpath(an_xpath))}
          else
            raise TypeError, "Predicate #{predicate.inspect} is not a symbol or proc."
          end
          
        end
      rescue Watir::Exception::TimeOutException => e
        @test_case.flunk "#{msg}: #{xpath.join(', ')} did not occur after #{wait_time} seconds"
      end
    end

    # fix problem with .set method being slow on linux
    # call .value to set field value but manually trigger javascript events after a field is edited
    def populate(field, text = nil, check_field_value = true)
        if (text != nil)
        end
          #    field.scrollIntoView #method name not available for Watir - Firewatir only
              field.focus
        #    field.select() #method name not available for Watir - Firewatir only
            field.fire_event("onSelect")
        #    field.fire_event("onValid")
            field.value = ""
            field.fireEvent("onKeyDown")
            field.fireEvent("onKeyPress")

            if (text != nil)
              field.value = text
              if (field.value != text && check_field_value == true)
                 raise ArgumentError, "After setting field value, value does
        not match: " + text + "::::  field.value =  " + field.value, caller
               end
            else
            end

            field.fireEvent("onfocus")
            field.fireEvent("onKeyUp")
            field.fireEvent("onChange")
            field.fireEvent("onBlur")
      end

  end

  module AcceptanceTestSession
    include ActionView::Helpers::NumberHelper
    def watir_session
      return SageTestSession.new(self)
    end
    #click on a button of a javascript alert message
     #click_no_wait must be called before this method is called
     #only works for IE
     #button is the text of the button to click.
     def startClicker(browser, button , waitTime= 60, user_input=nil )
         # get a handle if one exists
         hwnd = browser.enabled_popup(waitTime)  
         if (hwnd)  # yes there is a popup
           w = WinClicker.new
           if ( user_input ) 
             w.setTextValueForFileNameField( hwnd, "#{user_input}" )
           end  
           # "OK" or whatever the name on the button is
           w.clickWindowsButton_hwnd( hwnd, "#{button}" )
           #
           # this is just cleanup
           w=nil    
         end
       end

     def format_amount(amount)
       number_to_currency(amount, :precision => 2, :unit=> "", :separator => ".", :delimiter => "," )
       #"%.2f" %  amount
     end

     def current_session(*keys)
       url = current_session_url + "?"
       keys.each{|key| url += "k[]=#{key}&"}
       url.chomp!('&')
       self.b.goto url
       HashWithIndifferentAccess.new(YAML.load(self.b.text))
     end
     
  end
    
 
module FireWatir

  class Frame < Element
    def set( setThis )      
      @o.doKeyPress(setThis)
    end
  end

  class TextField
    def populate( text = nil, check_field_value = true )
      #      SageTestSession::populate self, text, check_field_value
        if (text != nil)
        end
           #    self.scrollIntoView #method name not available for Watir - Firewatir only
              self.focus
            # self.select() #method name not available for Watir - Firewatir only
            self.fire_event("onSelect")
            # self.fire_event("onValid")
            self.value = ""
            self.fireEvent("onKeyDown")
            self.fireEvent("onKeyPress")

            if (text != nil)
              self.value = text
              if (self.value != text && check_self_value == true)
                 raise ArgumentError, "After setting self value, value does not match: " + text + "::::  self.value =  " + self.value, caller
               end
            else
            end

            self.fireEvent("onfocus")
            self.fireEvent("onKeyUp")
            self.fireEvent("onChange")
            self.fireEvent("onBlur")
      end

  end


end