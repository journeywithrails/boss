$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../acceptance/acceptance_test_helper'
require File.dirname(__FILE__) + '/../acceptance/sage_accep_test'

class SageProductionTestFixtures
  def self.users(name)
    case name
    when :ping
      OpenStruct.new({
        :email => 'lastobelus@mac.com',
        :login => 'lastobelus@mac.com',
        :password => 'test'
      })
    else
      raise StandardError, "do not know a user named #{name}"
    end
  end
  
end

module Test #:nodoc:
  module Unit #:nodoc:
    class TestCase #:nodoc:
      def setup_fixtures;end
      def teardown_fixtures;end
    end
  end
end

class AdminUtility
  include AcceptanceTestSession
  def initialize
    @b = watir_session
  end
  
  def delete_user_if_exists(name)
  end
  
  def activate_user(name)
  end
end

class SageProductionTestCase < Test::Unit::TestCase
  def mailhost
  end
  
  def users(name)
    SageProductionTestFixtures.users(name)
  end
  
  def admin
    return AdminUtility.new
  end
  
  def method_missing(method, *args, &block)
    if %w{ access_keys billers bookkeepers bookkeeping_contracts configurable_settings contacts customers deliveries invitations invoices line_items logos pay_applications payments paypal_gateways roles roles_users schema_info users }.include(method.to_s) then
      raise StandardError, "can't use fixtures in Production Test. Add #{method}(#{args.first}) to SageProductionTestFixtures"
    else
      super
    end
  end  
end

class SageTestSession
  def self.default_port
    "80"
  end
  
  def self.default_host
    "early.billingboss.com"
  end
  
  def logs_in(name=nil)
    @username ||= name
    @username ||= :ping
    @user ||= @test_case.users(@username)
    @b.goto(login_url)
    @b.wait
    @b.text_field(:id,"login").set(@user.login)
    @b.text_field(:id,"password").set(@user.password)
    @b.button(:name, "commit").click

    @b.wait()
    #look for the flash message
    @test_case.assert_not_nil @b.contains_text("Logged in successfully")
    self
  end
  
end