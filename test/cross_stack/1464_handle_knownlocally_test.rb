$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

# http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1133

class HandleDestinationParamTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user = watir_session
    SSO::SAM.prepare
    SSO::SBB.prepare
    assert_recaptcha_off(@user)
    @user.logs_out_cas
    @debug=false
  end

  def test_hit_custom_domain
  end

end