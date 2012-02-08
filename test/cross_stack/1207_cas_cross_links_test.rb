$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'

# http://sage.svnrepository.com/sagebusinessbuilder/trac.cgi/ticket/1207

class CasCrossLinksTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    @user = watir_session.with(:castest)
    @user.logs_out_cas
  end

  def test_sbb_links
    # @debug=true
    service_url = Sage::Test::Server.sagebusinessbuilder.url + "/bob"
    @user.goto ::SSO::CAS.login_url(service_url)
    
    exit unless $test_ui.agree('on login page. continue?', true) if @debug
    
    # create account link
    element = @user.element_by_xpath("//div[@id='create-account-link']/a")
    assert element.exists?
    assert_equal ::SSO::SAM.signup_url(:sbb, service_url).downcase, element.href.downcase
    
    # forgot password link
    element = @user.link(:id, "forgot-password-link")
    assert element.exists?
    service_url = Sage::Test::Server.sagebusinessbuilder.url + "/bob"
    assert_equal ::SSO::SAM.forgot_password_url(:sbb, service_url).downcase, element.href.downcase
    
  end

  def test_bb_links
    # @debug=true
    service_url = Sage::Test::Server.billingboss.url + "/mary"
    default_service_url = Sage::Test::Server.sagebusinessbuilder.secure_url + "/signup"

    @user.goto ::SSO::CAS.login_url(service_url)
    
    exit unless $test_ui.agree('on login page. continue?', true) if @debug
    
    # create account link
    element = @user.link(:id, "create-account-link")
    assert element.exists?
    assert_equal ::SSO::SAM.signup_url(:bb, service_url).downcase, element.href.downcase
    
    # forgot password link
    element = @user.link(:id, "forgot-password-link")
    assert element.exists?
    assert_equal ::SSO::SAM.forgot_password_url(:bb, service_url).downcase, element.href.downcase
    
    # back to service link
    element = @user.link(:id, "back-to-service-link")
    assert element.exists?
    assert_equal service_url.downcase, element.href.downcase
    
    # login to sagespark link
    element = @user.link(:id, "login-to-sbb-link")
    assert element.exists?
    href = element.href.downcase
    # strip any session id
    href.gsub!(/;jsessionid=[^?]*/,'')
    assert_equal ::SSO::CAS.secure_login_url(default_service_url, false).downcase, href
    
    
  end
end