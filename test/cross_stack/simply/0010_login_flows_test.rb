$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/simply_test_helper'


class SimplyLoginFlowsTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.billingboss.ensure
    @user = watir_session
    SSO::SAM.prepare(true)
    @debug = false    
  end
  
  def test_login_flow
    current_url, api_token_guid = simply.create_login_browsal
    puts current_url
    puts api_token_guid
  end
  
end