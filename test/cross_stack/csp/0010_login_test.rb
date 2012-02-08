$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/csp_test_helper'
require File.dirname(__FILE__) + '/../sso'


class LoginTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.proveng.ensure
    Sage::Test::Server.csp.ensure
    @user = watir_session
    SSO::SBB.prepare(true)
    @debug = false    
  end

  def teardown
    @user.logs_out
  end
  
  def test_login_with_bad_password_fails
    assert @user.text_field(:id, 'user_session_login').exists?
    assert @user.text_field(:id, 'user_session_password').exists?
    
    # test bogus login fails
    @user.text_field(:id, 'user_session_login').set('test_clerk')
    @user.text_field(:id, 'user_session_password').set('bogusandwrong')
    @user.submits
    assert @user.text_field(:id, 'user_session_login').exists?
    assert @user.text_field(:id, 'user_session_password').exists?
    assert @user.text.include?("Password is not valid")
  end
  
  def test_login_succeeds
    @user.goto Sage::Test::Server.csp.url
    exit unless $test_ui.agree("what's up?", true) unless @user.text_field(:id, 'user_session_login').exists?
    assert @user.text_field(:id, 'user_session_login').exists?
    assert @user.text_field(:id, 'user_session_password').exists?
    
    # test bogus login fails
    @user.text_field(:id, 'user_session_login').set('test_clerk')
    @user.text_field(:id, 'user_session_password').set('test11')
    @user.submits
    exit unless $test_ui.agree("logged in?", true) if @debug
    deny @user.text_field(:id, 'user_session_login').exists?
    deny @user.text_field(:id, 'user_session_password').exists?
    assert @user.text.include?("Login successful")
    assert @user.div(:id, "accounts-active-scaffold").exists?
    
    # also test logout
    assert @user.link(:id, 'logout-link').exists?
    @user.link(:id, 'logout-link').click
    @user.wait_until_exists('user_session_login')
    
  end
end