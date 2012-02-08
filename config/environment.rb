# Be sure to restart your server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'
require 'rubygems'

begin
  gem 'test-unit' # in case the test-unit gem is installed, we must ensure it gets loaded first before the old built-in test unit
rescue Gem::LoadError => e
end

require 'rubygems'

#this is for loading the gems that have been frozen into the vendors/gems folder
# if we upgrad to a newer version of rails, the following three lines of code might need to be removed
gem_paths = ["#{File.dirname(__FILE__)}/../vendor/gems"] + Gem.path 
Gem.clear_paths
Gem.send :set_paths, gem_paths.join(":")


if %w{production staging}.include?(ENV['RAILS_ENV'])
  #strip out non-numeric letters from svn version because PrinceXML does not like
  # css link like this myfile.css?1233M
  ENV['RAILS_ASSET_ID'] ||= `svnversion -n`.gsub(/[^0-9]/,'')
else
  gem "ZenTest", "~> 4.1" # The last version that includes Test::RAILS
end


gem "gettext", "~>1.93.0"
gem "ZenTest", "~>4.1.4"
gem "uuidtools", "~> 2.0" # 2.0.0 was restructured so that UUID is inside the UUIDTools namespace

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

# tells the authorization plugin that we want to store roles in a table
AUTHORIZATION_MIXIN = "object roles"

# tells the authorization plugin where to redirect when a page/role is not permitted. 
# default  is account/login
 DEFAULT_REDIRECTION_HASH = { :controller => '/access', :action => 'denied' }

# tells the authorization plugin what the method is for storing the return
# location. default :store_return_location
STORE_LOCATION_METHOD = :store_location

# run patches on rails
# require File.join(File.dirname(__FILE__), '../lib/rails_patcher')
#Rails::Patcher.run


# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# need this to be here to avoid dependency catch-22 (with pidlogger in environments/test.rb)
class ProcessId
  def self.pid
    "#{::Socket.gethostname}-#{Process.pid}"
  end
end

# require 'action_mailer/ar_mailer'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default all plugins in vendor/plugins are loaded, in alphabetical order
  # :all can be used as a placeholder for all plugins not explicitly named.
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  
  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session_store = :cookie_store
  config.action_controller.session = {
    :session_key => '_tornado_session',
    :secret      => '89f6896c3a2b2b86a44eac626380e5cf0dccbe35d609f1d0528bbd2dac90a9dbefffc74c09223dacf375ed973d2c13c63beaa6169121a3e7cc0c3338e517c5e5',
    :session_expires_after => 3600
  }


  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options

  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory is automatically loaded
  require 'last_obelus/yaml/oyaml'
  puts "load appconfig"
  ::AppConfig = LastObelus::YAML::OYAML.load_scoped_config(File.join(RAILS_ROOT, 'config','application.yml'), RAILS_ENV)
end


Princely::Prince.windows_executable = ::AppConfig.pdf.prince.windows_executable

require 'sage/active_record/validations'
require 'last_obelus/action_view/helpers/conditional_parser_helper'
require 'last_obelus/action_view/fallback_formats'
require 'last_obelus/active_record/raising_valid'
require 'last_obelus/active_record/reject_unknown_attributes'
require 'last_obelus/object/unless_nil'
require 'last_obelus/concurrency/checkpoints'
require 'last_obelus/string/extensions'
require 'last_obelus/time'
require 'delegation'
require 'rails_override'
require 'patches/date'
require 'sage/action_view/helpers/active_merchant_country_helper'
require 'gettext/rails'
require 'uuidtools'
require 'country_select_options_override'
require 'last_obelus/active_record/valid_for_attributes'
require 'sage/active_merchant/filter_credit_card'
require 'module_before_filter'


ValidatesDateTime.us_date_format = true

CalendarDateSelect.format = :hyphen_ampm # or :natural
