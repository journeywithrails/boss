$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require 'hpricot'

# Test cases for Referral Test (no user story)
# User can invite a friend and get extra credit if friend signs up
# only asserting in this test what couldn't be asserted in unit/functionals
class ReferralTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    @user = watir_session.with(:user_without_profile)
    @user.stub_gateway
    exit unless $test_ui.agree("stubbed gateway. continue?", true) if @debug || $debug
  end
  
  def teardown
    end_email_server
    @user.teardown
  end
  
  def test_send_one_referral
    b = @user.b
    @user.goto_referral_url
    start_email_server
    b.wait
    assert_equal "", @user.text_field(:id, "referral_referrer_email").value
    #@user.text_field(:id, "referral_referrer_name").set "asdf"
    @user.logs_in
    @user.goto_home_url
    @user.goto_referral_url

    assert_equal "user_without_profile", @user.text_field(:id, "referral_referrer_email").value

    @user.populate(@user.text_field(:id, "referral_referrer_name"), "Me")
    @user.populate(@user.text_field(:id, "referral_referrer_email"), "me@me.com")
    @user.populate(@user.text_field(:id, "referral_friend_name_1"), "You")

    @user.populate(@user.text_field(:id, "referral_friend_email_1"), "you@you.com")
    @user.button(:id, "referral_submit").click
    @user.logs_out

    a = Referral.find(:first, :conditions => {:referring_email => "me@me.com", :friend_email => "you@you.com" })
    assert a
    assert !a.sent_at.blank?
    code = a.referral_code
    
    puts "code: #{code.inspect}"
    mail = get_last_sent_email()
    assert_not_nil(mail)
    hmail = Hpricot(mail.body)
    links = hmail.search("a[text()*='Get started now']")
    
    puts "links: #{links.inspect}"
    deny_empty links
    
    signup_url = links.first[:href]
    
    puts "signup_url: #{signup_url.inspect}"
    
    
    # Fake signup
    m = signup_url.match(/service=([^&]*)/)
    service_url = CGI::unescape(m[1])
    $debug = true
    @new_user = watir_session
    @new_user.stub_first_login("atest", "atest@billingboss.com")
    exit unless $test_ui.agree("setup first login. continue?", true) if @debug || $debug
    
    @new_user.goto(service_url)

    exit unless $test_ui.agree("went to service url. continue?", true) if @debug || $debug

    @new_user.goto_referral_welcome_url(code)
    
    @new_user.link(:class, "entry_button").click
    
    @new_user.goto_signup_url


    @new_user.button(:id, "register_button").click
    b.wait
     
    @new_user.populate(@new_user.text_field(:id, "user_login"), "atest")
    @new_user.populate(@new_user.text_field(:id, "user_email"), "atest@atest.com")
    @new_user.populate(@new_user.text_field(:id, "user_password"), "asdf")
    @new_user.populate(@new_user.text_field(:id, "user_password_confirmation"), "asdf")
    @new_user.checkbox(:id, "user_terms_of_service").set true
    @new_user.button(:id, "register_button").click
    b.wait

   
    a2 = Referral.find(:first, :conditions => {:referral_code => code })    

    assert !a2.accepted_at.blank?
    accepted_time = a2.accepted_at

    u = User.find(:first, :conditions => {:sage_username => "atest"})
    assert !a2.user_id.blank?
    assert_equal u.id, a2.user_id
    
    @user.goto_signup_url

    @user.populate(@user.text_field(:id, "user_login"), "atest2")
    @user.populate(@user.text_field(:id, "user_email"), "atest2@atest.com")
    @user.populate(@user.text_field(:id, "user_password"), "asdf")
    @user.populate(@user.text_field(:id, "user_password_confirmation"), "asdf")
    @user.checkbox(:id, "user_terms_of_service").set true
    @user.button(:id, "register_button").click
    b.wait
    a3 = Referral.find(:first, :conditions => {:referral_code => code })    
    assert (a3.accepted_at == accepted_time)
    end_email_server
  end
  
  def test_ssan_user_logged_in_as_ssan
    @user = watir_session.with(:ssan_user)
    b = @user.b
    @user.logs_in
    b.wait
    @user.goto_home_url
    b.wait
    @user.goto_referral_url
    b.wait
    assert_equal "ssan_text", @user.span(:id, "ssan_text").id

    @user.populate(@user.text_field(:id, "referral_referrer_name"), "Me")
    @user.populate(@user.text_field(:id, "referral_referrer_email"), "me@me.com")
    @user.populate(@user.text_field(:id, "referral_friend_name_1"), "You")
    @user.populate(@user.text_field(:id, "referral_friend_email_1"), "you@you.com")
    @user.button(:id, "referral_submit").click
    b.wait
    r = Referral.find(:first)
    assert_equal "ssan", r.referring_type
  end
  
end