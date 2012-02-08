require 'rubygems'

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
#remove to fix test failures
require "cas_test_helper"
require 'babel'
require 'rumbster'

require 'hpricot'
require 'uuidtools'
require 'highline'

require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')
require File.expand_path(File.dirname(__FILE__) + '/integration_session_extensions')
require File.expand_path(File.dirname(__FILE__) + '/simply_api_test_helpers')
require File.expand_path(File.dirname(__FILE__) + '/sam_test_helper')

$test_ui = HighLine.new

#require 'test_timer'
# puts "requiring singleton_class"
# require 'last_obelus/kernel/singleton_class'

module Sage
  module Test
    module Unit
      module Assertions
        # replace assertions that were in ZenTest 3
        def assert_empty(thing, msg=nil)
          assert thing.empty?, msg
        end

        def deny_empty(thing, msg=nil)
          deny thing.empty?, msg
        end

        def deny test, msg=nil
          if msg then
            assert ! test, msg
          else
            assert ! test
          end
        end unless respond_to? :deny

        def deny_match(pattern, string, message="")
          _wrap_assertion do
            pattern = case(pattern)
            when String
              Regexp.new(Regexp.escape(pattern))
            else
              pattern
            end
            full_message = build_message(message, "<?> expected to not =~\n<?>.", string, pattern)
            assert_block(full_message) { !(string =~ pattern) }
          end
        end
      end
    end
  end
end

class ActionController::Integration::Session
  include Sage::Test::Unit::Assertions
end

class Test::Unit::TestCase
  #include helpers for Acts as Authenticated plugin
  include CasTestHelper
  include SamTestHelper
  include Sage::Test::Unit::Assertions
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  # If you need to control the loading order (due to foreign key constraints etc), you'll
  # need to change this line to explicitly name the order you desire.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherent this setting
  fixtures :all


  # RSpec-style ActiveRecord model mocking
  def mock_model(klass, stubs = {})
    @@model_id ||= 0
    id = ( @@model_id += 1 )
    m = mock("#{klass.name.underscore}_#{id}")
    m.stubs(:id).returns(id)
    m.stubs(:to_param).returns(id.to_s)
    m.stubs(:class).returns(klass)
    m.stubs(:new_record?).returns(false)
    m.stubs(:is_a?).returns(false)
    m.stubs(:is_a?).with(klass).returns(true)
    m.stubs(:valid?).returns(true)
    m.stubs(:errors).returns( stub('errors', :count => 0) )
    m.stubs(stubs)
    m
  end


  def initialize_with_unstub_cas(name)
    puts "initialize_with_unstub_cas #{name}"
    unstub_cas
    puts "call original initialize with #{name}"
    initialize_without_unstub_cas(name)
  end
  alias_method_chain :initialize, :unstub_cas unless method_defined?(:initialize_with_unstub_cas)
  
  
  # use activemerchant in test mode
  ActiveMerchant::Billing::Base.mode = :test
  
  # Add more helper methods to be used by all tests here...
  def assert_not_valid(model,msg="record was valid but shouldn't be")
    assert_block(msg) { !model.valid? }
  end
  

  def assert_state (model, state, msg="")
    assert model.send("#{state.to_s}?".to_sym), "expected #{model.class} to be in state #{state.to_s} but was in state #{model.status} #{msg}"
  end
  
  def deny_state (model, state, msg="")
    deny model.send("#{state.to_s}?".to_sym), "expected #{model.class} not to be in state #{state.to_s} but was in state #{model.status} #{msg}"
  end
  
  def self.is_windows?
    return ENV['OS'] == 'Windows_NT'
  end
  
  def paypal_test_api_developer_account
    ENV['PAYPAL_TEST_DEVELOPER_ACCOUNT'] || 'tornadoproduction@gmail.com'
  end
  
  def paypal_test_api_developer_password
    ENV['PAYPAL_TEST_DEVELOPER_PASSWORD'] || 'simply#1'
  end
  
  def paypal_test_api_key
    ENV['PAYPAL_TEST_API_KEY'] || 'AA1zqGy1xARjWyYc42x5cn1eG9iQAGcsE0RepP1jo7Lvx.wtUKMHNbfd'
  end
  
  def paypal_test_api_username
    ENV['PAYPAL_TEST_API_USERNAME'] || 'tornad_1195495881_biz_api1.gmail.com'
  end

  def paypal_test_api_password
    ENV['PAYPAL_TEST_API_PASSWORD'] || '1195495892'
  end

  def paypal_test_api_merchant_account
    ENV['PAYPAL_TEST_MERCHANT_ACCOUNT'] || 'tornad_1195495881_biz@gmail.com'
  end

  def paypal_test_api_merchant_password
    ENV['PAYPAL_TEST_MERCHANT_PASSWORD'] || 'simply#1'
  end

  def paypal_test_api_buyer_account
    ENV['PAYPAL_TEST_BUYER_ACCOUNT'] || 'tornad_1195495736_per@gmail.com'
  end

  def paypal_test_api_buyer_password
    ENV['PAYPAL_TEST_BUYER_PASSWORD'] || 'simply#1'
  end
  
  
  
  def add_valid_invoice(user, options = {})
    customer = options[:customer_attributes].nil? ? user.customers[rand(user.customers.length)] : nil
    options = {
      :customer => customer,
      :date => Time.now,
      :due_date => Time.now + 1.week,
      :description => Babel.random_short.gsub( '&', 'and' ),
    }.merge(options)

    if options.has_key?(:line_items)
      line_item_options = options.delete(:line_items)
      if line_item_options.is_a?(String)
        line_item_options = rand(25)
      end
      if line_item_options.is_a?(Fixnum)
        lio = []
        line_item_options.times{lio << {}}
        line_item_options = lio
      end
    else
      line_item_options = [{}]      
    end
    line_item_options ||= []

    invoice=user.invoices.create(options)
    line_item_options.each { |li| add_valid_line_item(invoice, li)  }
    invoice.save
    return invoice
  end
  
  def add_paypal_credentials(user)
    user.profile.paypal_user_id = paypal_test_api_username
    user.profile.paypal_password = paypal_test_api_password
    user.profile.paypal_API_key = paypal_test_api_key
    user.profile.paypal_account_type = Profile.paypal_account_types["Paypal Business"]
    user.profile.save!
    user
  end
  
  def add_valid_line_item(invoice, options = {})
    options = {
      :unit => Babel.random_short.gsub( '&', 'and' ),
      :quantity => 1,
      :price => BigDecimal("5.00")
    }.merge(options)
    line_item = invoice.line_items.create(options)
    invoice.save!
    line_item
  end
  
  def add_valid_customer(user, options = {})
    options = {
      :name => Babel.random_short.gsub( '&', 'and' ),
      :language => "en_US"
    }.merge(options)
    
    if options.has_key?(:contacts)
      contact_options = options.delete(:contacts)
    else
      contact_options = [{}]      
    end
    
    contact_options ||= []
    cust=user.customers.create(options)
    contact_options.each { |co| add_valid_contact(cust, co)  }
    cust.reload
    return cust
  end

  def add_valid_contact(customer, options = {})
    options = {
      :first_name => Babel.produce(1).capitalize,
      :last_name => Babel.produce(1).capitalize,
      :email => Babel.produce(1).downcase + '@test.com'      
    }.merge(options)
    contact = customer.contacts.create(options)
    customer.save
    contact
  end
  
  def show_last_delivery_errors
    d = Delivery.find :first, :order => 'id desc'
    puts d.error_details
  end
  
  def assert_last_delivery_had_no_errors
    d = Delivery.find :first, :order => 'id desc'
    assert_not_nil d
    assert_nil d.error_details
  end
  
  def assert_layout layout
    assert_equal layout, @response.layout, "the expected layout should be #{layout} and is #{@response.layout}"
  end   
  
  def big_zero
    BigDecimal.new("0")
  end
  
  def start_email_server
    @observer = MailSingleMessageObserver.new
    $server = Rumbster.new(2000)
    $server.add_observer(@observer)    
    $server.start      
  end
  
  def end_email_server
    $server.stop unless ($server.nil?)
  end
  
  def get_last_sent_email()
    @observer.message
  end

  
  def set_http_authorization(user=::AppConfig.service_provider.admin_user, password=::AppConfig.service_provider.admin_password)
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{user}:#{password}")    
  end
  
  # I originally called this function test_host. then testhost. Then I finally clued in wth was going on. duh.
  def host_for_test
    if @controller.nil?
      ::AppConfig.host.sub('http://', '')
    else
      @controller.send(:default_url_options, nil)[:host]
    end
  end

  def url_to_params(url)
    require 'uri'
    uri = URI.parse(url)
    CGI.parse(uri.query).with_indifferent_access
  end
end

