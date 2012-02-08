$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class KnownLocallyTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user = watir_session.with_sage_user(:castest)
    SSO::SAM.prepare
    SSO::SBB.prepare(true)
    @user.logs_out_cas
    @debug = false
  end

  def test_site_comes_up
    # @debug=true
    @user.goto Sage::Test::Server.knownlocally.url
    $test_ui.agree('knownlocally home page. continue?', true) if @debug
    assert_knownlocally_theme(@user, @debug)
    $test_ui.agree('continue?', true) if @debug
  end
  
  def test_registered_domain
    @user.with_sage_user(:castest_with_business_profile)
    assert_click_goto_sbb_and_click_login(@user, @debug)
    assert_cas_login(@user, @debug)
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/users/castestwithbusinessprofile"
    @user.goto Sage::Test::Server.sagebusinessbuilder.url + "/mysage/myprofile/edit/business_info"
    $test_ui.agree('click business information?', true) if @debug
    @user.link(:text, "Business Information").click
    @user.text_field(:name,"title").set("Test of Registered Domains")
    @user.select_list(:id, 'industry_drop_down').select_value('161')
    @user.button(:name, 'op').click
    
    # @debug=true
    SSO::SBB.add_registered_domain("castest_with_business_profile", "castest.com")
    `ghost add www.castest.com`
    @user.goto Sage::Test::Server.sagebusinessbuilder.url("www.castest.com")
    assert_knownlocally_theme(@user, @debug)
    $test_ui.agree('continue?', true) if @debug
  end
end