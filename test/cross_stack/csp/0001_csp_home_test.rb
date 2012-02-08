$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/csp_test_helper'
require File.dirname(__FILE__) + '/../sso'


class CspHomeTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.proveng.ensure
    Sage::Test::Server.csp.ensure
    @user = watir_session
    SSO::SBB.prepare(true)
    @debug = false    
  end
  
  def test_comes_up
    @user.goto Sage::Test::Server.csp.url
    assert @user.text.include?("Customer Service Portal")
  end
  
end