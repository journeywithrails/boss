$:.unshift(File.dirname(__FILE__) + '/../lib')
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

# require 'rubygems'
# require 'test/unit'
# require 'active_record'
# require 'active_record/fixtures'
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'test_help'

require "#{File.dirname(__FILE__)}/../init"


config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite'])

begin
  load(File.dirname(__FILE__) + "/schema.rb") if File.exist?(File.dirname(__FILE__) + "/schema.rb")
rescue
  puts "already created"
end

class Test::Unit::TestCase
end
Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
end