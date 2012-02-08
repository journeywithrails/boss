$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'


class BbTest < Test::Unit::TestCase
  include AcceptanceTestSession

# RADAR: note currently bb locale handling is fubarred. If you use locale=de_DE, you won't get german because it checks the whole local against the available_languages. If you use de, you will get de_US because the country will get set to US. If someone chooses to fix this, please also make this test more better

  def setup
    # $log_on = true
    Sage::Test::Server.cas_server_sage.ensure
    Sage::Test::Server.sagebusinessbuilder.ensure
    Sage::Test::Server.sageaccountmanager.ensure
    Sage::Test::Server.billingboss.ensure
    @user = watir_session.with_sage_user(:castest)
    SSO::SAM.prepare
    assert_recaptcha_off(@user)
    SSO::SBB.prepare(true)
    @user.logs_out_cas
    @debug = false
  end
  
  def test_signup_sends_locale_to_sam
    # @debug = true
    @user.goto Sage::Test::Server.billingboss.url + "?locale=de"
    assert_page_in_locale('de_US')
    @user.link(:text, /sign ?up/i).click    
    exit unless $test_ui.agree('clicked signup. continue?', true) if @debug
    assert_on_bb_signup_page(@user)
    assert_page_in_locale('de_US')
  end
  
  def test_login_sends_locale_to_cas
    @user.goto Sage::Test::Server.billingboss.url + "?locale=de"
    assert_page_in_locale('de_US')
    assert_click_goto_bb_and_click_login(@user, @debug)
    assert_cas_login(@user, @debug)
    assert_page_in_locale('de_US')
  end
  
  def test_cas_sends_locale_to_bb_after_change
    @user.goto Sage::Test::Server.billingboss.url + "?locale=de"
    # @debug = true
    assert_page_in_locale('de_US')
    assert_click_goto_bb_and_click_login(@user, @debug)
    assert_cas_login(@user, @debug)
    assert_page_in_locale('de_US')
    @user.goto @user.url + "?locale=fr"
    assert_page_in_locale('fr_US')
    
  end
  
  def test_sam_sends_locale_to_bb_after_change
    @user.goto Sage::Test::Server.billingboss.url + '/caslogout' # ensure starting logged out even is single sign out isn't working
    @user.with_sage_user(random_new_sage_user)
    
    @user.goto Sage::Test::Server.billingboss.url
    @user.link(:text, /sign ?up/i).click
    assert_on_bb_signup_page(@user)
    assert_page_in_locale('de_US')
    @user.goto @user.url + 'locale=fr'
    assert_page_in_locale('fr_US')
    user_fills_in_sam_signup_form(@user)
    
    exit unless $test_ui.agree('click register on sam?', true) if @debug
    @user.button(:id, "register_button").click
    exit unless $test_ui.agree('clicked register on sam. continue?', true) if @debug

    #Note: existing user will see a successful login message
    @debug = true
    assert_logged_in_on_bb(@user, @debug)

    assert_logout_elsewhere_logsout_bb(@user, @debug)

  end
  
  def assert_page_in_locale(locale)
    exit unless $test_ui.agree("about to assert page is in locale #{locale}?", true) if @debug
    puts @user.html.scan(/<!-- Locale:[^>]*/)
    assert @user.html.include?("<!-- Locale: #{locale} -->"), "page should have locale comment with locale #{locale}"
  end
    
end