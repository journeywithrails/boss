require 'sage/test/server'
Sage::Test::Server.configure

# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.default_url_options = {:host => Sage::Test::Server.billingboss.url, :only_path => false}

case ENV["TORNADO_MAILSERVER"]
when 'shaw'
  puts "still using shaw smtp server"
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address  => "shawmail.vc.shawcable.net",
    :port  => 25, 
    # :user_name  => "lastobelus",
    # :password  => "lastobelus",
    # :authentication  => :login
  }
when 'gmail'
  puts "using gmail live server"
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :tls => true,
    :address => 'smtp.gmail.com',
    :port => 587,
    :domain => "billingboss.com",
    :authentication => :plain,
    :user_name => 'tornadoproduction@gmail.com',
    :password => 'simplybillingboss'
  } 

else
  if ENV['OFFLINE'] 
    puts "using delivery_method = test"
    config.action_mailer.delivery_method = :test
    config.action_mailer.raise_delivery_errors = false
  else
    puts "for now i am making this SMTP server comment. which i need to remove laters."
    puts "using delivery_method = test"
    config.action_mailer.delivery_method = :test
    config.action_mailer.raise_delivery_errors = false


    #puts "using local SMTP server on port 2000. Make sure you have a SMTP server running locally"
    #config.action_mailer.raise_delivery_errors = true
    #config.action_mailer.delivery_method = :smtp
   # # config.action_mailer.smtp_settings = {
   # #   :address  => "10.152.17.65",
   # #   :port  => 2500,  
   # # }
   # config.action_mailer.smtp_settings = {
   #   :address  => "localhost",
    #  :port  => 2000,  
    #}
  
  end
end


ActiveMerchant::Billing::Base.gateway_mode = :test


class ::ActiveSupport::PidLogger < ::ActiveSupport::BufferedLogger
  class << self
    def skip=(value)
      @@skip = value
    end
    def skip
      @@skip
    end
  end
    
  def debug(message, *args)
    return if ::ActiveSupport::PidLogger.skip
    if block_given?
      super(message, *args) { "#{ ::ProcessId.pid }: #{ yield }" }
    else
      super("#{ ::ProcessId.pid }: #{ message }", *args)
    end
  end
  def info(message, *args)
    return if ::ActiveSupport::PidLogger.skip
    if block_given?
      super(message, *args) { "#{ ::ProcessId.pid }: #{ yield }" }
    else
      super("#{ ::ProcessId.pid }: #{ message }", *args)
    end
  end
  def warn(message, *args)
    return if ::ActiveSupport::PidLogger.skip
    if block_given?
      super(message, *args) { "#{ ::ProcessId.pid }: #{ yield }" }
    else
      super("#{ ::ProcessId.pid }: #{ message }", *args)
    end
  end
  def error(message, *args)
    return if ::ActiveSupport::PidLogger.skip
    if block_given?
      super(message, *args) { "#{ ::ProcessId.pid }: #{ yield }" }
    else
      super("#{ ::ProcessId.pid }: #{ message }", *args)
    end
  end
  def fatal(message, *args)
    return if ::ActiveSupport::PidLogger.skip
    if block_given?
      super(message, *args) { "#{ ::ProcessId.pid }: #{ yield }" }
    else
      super("#{ ::ProcessId.pid }: #{ message }", *args)
    end
  end
  def unknown(message, *args)
    return if ::ActiveSupport::PidLogger.skip
    if block_given?
      super(message, *args) { "#{ ::ProcessId.pid }: #{ yield }" }
    else
      super("#{ ::ProcessId.pid }: #{ message }", *args)
    end
  end
end


config.log_level = (ENV['RAILS_LOG_LEVEL'] && ENV['RAILS_LOG_LEVEL'].to_sym) || :debug

if ENV['RAILS_LOG_LEVEL'] == 'skip'
  puts "attempting to disable logging altogether" # what other hoops do I have to jump through to actually turn off all logging here?
  config.log_level = :fatal
  ::ActiveSupport::PidLogger.skip = true
  RAILS_DEFAULT_LOGGER = ActiveSupport::PidLogger.new(File.join(RAILS_ROOT, 'log', "test.log"), ActiveSupport::BufferedLogger::FATAL)
  ActionController::Base.logger = nil
  ActiveRecord::Base.logger = nil
  ActiveSupport::Cache::Store.logger = nil
else
  ::ActiveSupport::PidLogger.skip = false
  puts "using a log level of #{config.log_level}"
  config.log_level = (ENV['RAILS_LOG_LEVEL'] && ENV['RAILS_LOG_LEVEL'].to_sym) || :debug
  # RAILS_DEFAULT_LOGGER = ActiveSupport::PidLogger.new(File.join(RAILS_ROOT, 'log', "test.log"), ActiveSupport::BufferedLogger.const_get(config.log_level.to_s.upcase))
end


config.after_initialize do
  require 'zentest'
 
  require 'test/mock_cas_controller'

  puts "reset test urls in appconfig"
  ::AppConfig.sageaccountmanager.url = Sage::Test::Server.sageaccountmanager.url 
  ::AppConfig.sagebusinessbuilder.url = Sage::Test::Server.sagebusinessbuilder.url 
  ::AppConfig.host = Sage::Test::Server.billingboss.url

  # enable detailed CAS logging
  cas_logger = CASClient::Logger.new(RAILS_ROOT+'/log/cas.log')
  cas_logger.level = Logger::FATAL
  
  
  CASClient::Frameworks::Rails::Filter.configure(
    # :cas_base_url  => "https://localhost:8443/cas/",
    :cas_base_url  => Sage::Test::Server.cas_server_sage.url,
    :user_prefill => true,
    :add_locale => true,
    :username_session_key => :sage_user,
    :session_extra_attributes_key => :cas_extra_attributes,
    # :logger => cas_logger,
    :filter_implementation => "CookieSessionFilterImplementation",
    :authenticate_on_every_request => false,
    :check_cas_status => true,
    :verify_ssl_certificate => false
  )
  
end
