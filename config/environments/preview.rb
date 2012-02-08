# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new
config.log_level = :debug

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
config.action_controller.page_cache_directory = RAILS_ROOT+"/public/cache/"

# site to use for session_domain
config.action_controller.session :session_domain => '.billingboss.com'

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
#config.action_mailer.delivery_method = :test
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_url_options = {:host => 'www.billingboss.com', :only_path => false}


 
 #RADAR: Remove PW from here when we have another solution
  puts "using electricmail"
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    # :tls => true,
    :address  => "outbound.electric.net",
    :authentication => :login,
    :password => "g00gle$",
    :domain => "billingboss.com",
    :user_name => "info@billingboss.com",
    :port  => 25
  }
     
config.after_initialize do
  require 'zentest'

  # enable detailed CAS logging
  cas_logger = CASClient::Logger.new(RAILS_ROOT+'/log/cas.log')
  cas_logger.level = Logger::DEBUG

  CASClient::Frameworks::Rails::Filter.configure(
    :cas_base_url  => "https://localhost/",
    :login_url     => "https://localhost/login",
    :logout_url    => "https://localhost/logout",
    :validate_url  => "https://localhost/proxyValidate",
    :username_session_key => :sage_user,
    :session_extra_attributes_key => :cas_extra_attributes,
    :logger => cas_logger,
    :filter_implementation => "CookieSessionFilterImplementation",
    :authenticate_on_every_request => false
  )
end
