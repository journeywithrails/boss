config.action_controller.page_cache_directory = RAILS_ROOT+"/public/cache/"
# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
if ENV['PROFILE_RAILS']
  puts "caching classes"
  config.cache_classes = true
else
  puts "NOT caching classes"
  config.cache_classes = false
end

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
config.action_view.cache_template_extensions         = false
config.action_view.debug_rjs                         = true

my_port = ENV["MONGREL_PORT"] || '3000'
config.action_mailer.default_url_options = {:host => "billingboss.simplytest.com:#{my_port}", :only_path => false}

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
    puts "using Tornado private smtp server"
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      :address  => "localhost",
      :port  => 2500,  
    }
  end
end
ActiveMerchant::Billing::Base.gateway_mode = :test
ActionMailer::Base.perform_deliveries = true

config.after_initialize do

  # enable detailed CAS logging
  cas_logger = CASClient::Logger.new(RAILS_ROOT+'/log/cas.log')
  cas_logger.level = Logger::DEBUG

  CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url  => "https://login.simplytest.com:8443/cas/",
  :user_prefill => true,
  :add_locale => true,
  :username_session_key => :sage_user,
  :verify_ssl_certificate => false,
  :session_extra_attributes_key => :cas_extra_attributes,
  # :logger => RAILS_DEFAULT_LOGGER,
  :filter_implementation => "CookieSessionFilterImplementation",
  :authenticate_on_every_request => false,
  :verify_ssl_certificate => false

  )
end
