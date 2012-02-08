require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/../../acceptance/acceptance_test_helper'
require File.dirname(__FILE__) + '/../../cas_acceptance_helper'


class Test::Unit::TestCase
  def valid_cc_attributes(attrs)
    {
      :ccard_type => "4 - Visa",
      :ccard_num => '4111111111111111',
      :ccard_name => attrs[:account_name],
      :ccard_expiry_year => 2011,
      :ccard_expiry_month => 5,
      :ccard_cvv2 => 412
    }.merge(attrs)
  end
  
  def invalid_cc_attributes(attrs)
    {
      :ccard_type => "4 - Visa",
      :ccard_num => '4111111111111152',
      :ccard_name => attrs[:account_name],
      :ccard_expiry_year => 2011,
      :ccard_expiry_month => 5,
      :ccard_cvv2 => 412
    }.merge(attrs)
  end

  def valid_account_attributes(attrs={})
    valid_account = {
      :account_name => "basic_user",
      :client_id => "",
      :first_name => "Basic",
      :last_name => "Yewser",
      :company => "Basic Inc.",
      :email => "basic_user@billingboss.com",
      :phone => "604-555-5555",
      :fax => "604-555-5556",
      :address => "123 Street",
      :city => "Cityville",
      :country => "Canada",
      :state_prov => 'BC - British Columbia',
      :zip_postal => "12345",
    }.merge(attrs)
    valid_account.merge!(valid_cc_attributes(valid_account)) unless valid_account.keys.detect{|k| k =~ /^ccard_/}
  end
  
  
end

class SageTestSession
  def logs_out
    @b.goto Sage::Test::Server.csp.url unless @b.url == Sage::Test::Server.csp.url
    if @b.link(:id, 'logout-link').exists?
      @b.link(:id, 'logout-link').click
      wait_until_exists('user_session_login')
    end
  end
  
  def logs_in_as_clerk(debug=false)
    logs_out
    logs_in({:username => 'test_clerk', :password => 'test11'}, debug)
  end
  
  def logs_in(user_dict, debug=false)
    @b.goto Sage::Test::Server.csp.url unless @b.url == Sage::Test::Server.csp.url

    @b.text_field(:id, 'user_session_login').set(user_dict[:username])
    @b.text_field(:id, 'user_session_password').set(user_dict[:password])
    submits
    exit unless $test_ui.agree("assert login successful?", true) if debug
    # wait_until_exists("accounts-active-scaffold")

    begin
      Watir::Waiter.new(5, 1).wait_until do
        @b.element_by_xpath("id('accounts-active-scaffold')").exists?
      end
    rescue Watir::Exception::TimeOutException => e
      debugger
    end
    
    @test_case.assert @b.div(:id, "accounts-active-scaffold").exists?
  end
  
  
end