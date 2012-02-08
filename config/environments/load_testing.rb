# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_controller.page_cache_directory = RAILS_ROOT+"/public/cache/"

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
#config.action_mailer.delivery_method = :test
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_url_options = {:host => 'www.mybillingboss.com', :only_path => false}


config.action_mailer.delivery_method = :sendmail
# config.action_mailer.sendmail_settings = {
#   :location       => '/opt/csw/sbin/sendmail',
#   :arguments      => '-i -t -f "BillingBosss <info@billingboss.com>" -X/var/log/mail.log'
# }
# 


config.action_mailer.delivery_method = :test


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
