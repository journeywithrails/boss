$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class SbbConstructsSecureServiceTest < Test::Unit::TestCase
  include AcceptanceTestSession

  # see https://secure3.svnrepository.com/s_celeduc/sagebusinessbuilder/trunk/doc/cas_secure_pages_interaction.rtfd

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user = watir_session.with_sage_user(:castest_with_business_profile)
    SSO::SAM.prepare
    assert_recaptcha_off(@user)
    SSO::SBB.prepare(true)
    @user.logs_out_cas
    @debug = false
  end

  def test_sbb_redircts_to_cas_with_secure_service
    # @debug = true
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + '/job/myjobs'
    assert_on_cas_login_page(@user, @debug)
    service_url = extract_service_param_from_url(@user, @debug)
    assert_match "https://", service_url
  end
end