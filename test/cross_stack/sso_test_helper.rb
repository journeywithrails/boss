require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../acceptance/acceptance_test_helper'
require File.dirname(__FILE__) + '/../cas_acceptance_helper'


class Test::Unit::TestCase
  
  def assert_recaptcha_off(user, debug=false)
    user.goto Sage::Test::Server.sageaccountmanager.url + "/admin/dashboard/captcha?disabled=1"
    exit unless $test_ui.agree('recaptch off?', true) if debug
    assert user.contains_text("Recaptcha OFF")
  end
  
  def assert_click_goto_sbb_and_click_login(user, debug=false)
    user.goto Sage::Test::Server.sagebusinessbuilder.url
    exit unless $test_ui.agree('went to sbb. click login?', true) if debug
    assert_no_warning(user, debug)
    assert user.link(:id, "login-link").exists?
    user.link(:id, "login-link").click
    exit unless $test_ui.agree('clicked login. continue?', true) if debug
  end

  def assert_click_goto_bb_and_click_login(user, debug=false)
    user.goto Sage::Test::Server.billingboss.url
    exit unless $test_ui.agree('went to bb. click login?', true) if debug
    assert_no_warning(user, debug)
    assert user.link(:id, "login-link").exists?
    user.link(:id, "login-link").click
    exit unless $test_ui.agree('clicked login. continue?', true) if debug
  end

  def assert_on_profile_choice(user)
    assert user.contains_text("Sign up")
    assert @user.contains_text(/business profile/i)
    assert @user.contains_text(/personal profile/i)
  end
  
  def assert_on_cas_login_page(user, debug=false)
    exit unless $test_ui.agree('about to assert on login page. continue?', true) if debug
    assert user.button(:name, "login-btn").exists?, "should be on login page and have a login-btn"
    assert user.text_field(:id,"username").exists?, "should be on login page and have username text field"
    assert_match /#{Sage::Test::Server.cas_server_sage.url}/, user.url(), "Does not see the login page when clicking login. Actual URL is " + user.url    
  end
  
  def assert_cas_login(user, debug=false, check_warnings=true)
    assert_on_cas_login_page(user, debug)
    user.text_field(:id,"username").set(user.user.username)
    user.text_field(:id,"password").set("test")
    exit unless $test_ui.agree('click login?', true) if debug
    user.button(:name, "login-btn").click
    assert_no_warning(user, debug) if check_warnings
  end
  
  def assert_user_can_logout_from_sbb(user, debug=false, check_warnings=true)
    assert user.link(:id, "logout-link").exists?, "should be a logout link on the page"
    deny user.link(:id, "login-link").exists?, "should not be a login-link on the page"
    assert_no_warning(user, debug) if check_warnings
    user.link(:id, "logout-link").click
  
    deny user.link(:id, "logout-link").exists?, "should not be a logout link on the page"
    assert user.link(:id, "login-link").exists?, "should be a login link on the page"
    assert_no_warning(user, debug) if check_warnings
  end
  
  def assert_user_can_logout_from_bb(user, debug=false, check_warnings=true)
    assert user.link(:id, "logout-link").exists?, "should be a logout link on the page"
    deny user.link(:id, "login-link").exists?, "should not be a login-link on the page"
    assert_no_warning(user, debug) if check_warnings
    user.link(:id, "logout-link").click
  
    deny user.link(:id, "logout-link").exists?, "should not be a logout link on the page"
    assert user.link(:id, "login-link").exists?, "should be a login link on the page"
    assert_no_warning(user, debug) if check_warnings
  end
  
  def assert_logout_elsewhere_logsout_sbb(user, debug=false)
    assert_no_warning(user, debug)
    assert user.link(:id, "logout-link").exists?, "should be a logout link on the page"
    $test_ui.agree('logout elsewhere?', true) if debug
    user.logs_out_cas_from_cas # this goes to cas logout url, doesn't click logout in sbb
    $test_ui.agree('loggedout elsewhere. continue?', true) if debug
  
    user.goto Sage::Test::Server.sagebusinessbuilder.url
    $test_ui.agree('home page. continue?', true) if debug
  
    deny user.link(:id, "logout-link").exists?, "should not be a logout link on the page"
    deny user.contains_text(user.user.username.capitalize)
    assert user.link(:id, "login-link").exists?
    assert_no_warning(user, debug)
  end
  
  def assert_logout_elsewhere_logsout_bb(user, debug=false)
    assert_no_warning(user, debug)
    assert user.link(:id, "logout-link").exists?, "should be a logout link on the page"
    $test_ui.agree('logout elsewhere?', true) if debug
    user.logs_out_cas_from_cas # this goes to cas logout url, doesn't click logout in bb
    $test_ui.agree('loggedout elsewhere. continue?', true) if debug
  
    user.goto Sage::Test::Server.billingboss.url
    $test_ui.agree('home page. continue?', true) if debug
  
    deny user.link(:id, "logout-link").exists?, "should not be a logout link on the page"
    deny user.contains_text(user.user.username.capitalize)
    assert user.link(:id, "login-link").exists?
    assert_no_warning(user, debug)
  end  
  
  def user_fills_in_sam_signup_form(user, attrs=nil, debug=false)
    attrs ||= user.user
    sage_user = valid_sage_user(attrs)
    user.text_field(:id,"sage_user_username").set(sage_user.username)
    user.text_field(:id,"sage_user_email").set(sage_user.email)

    user.text_field(:id,"sage_user_password").set sage_user.password
    user.text_field(:id,"sage_user_password_confirmation").set sage_user.password_confirmation
    # attempt to work around sporadic problem with firewatir & the ajax password check
    Watir::Waiter.new(30).wait_until do
      if (user.text_field(:id,"sage_user_password").value == sage_user.password) &&
          (user.text_field(:id,"sage_user_password_confirmation").value == sage_user.password)
        true
      else
        puts "skipping ajax check because it is being lameass" if debug
        sleep(1)
        user.text_field(:id,"sage_user_password").value = sage_user.password
        user.text_field(:id,"sage_user_password_confirmation").value = sage_user.password_confirmation
        sleep(1)
        false
      end
    end
    
    user.checkbox(:id, "sage_user_terms_of_service").click if sage_user.terms_of_service
  end
  
  def user_fills_in_bb_signup_form(user, attrs=nil)
    attrs ||= user.user
    sage_user = valid_sage_user(attrs)
    user.text_field(:id,"sage_user_username").set(sage_user.username)
    user.text_field(:id,"sage_user_email").set(sage_user.email)
    user.text_field(:id,"sage_user_password").set(sage_user.password)
    # deal with java script check, re enter password
    user.text_field(:id,"sage_user_password").set(sage_user.password)
    user.text_field(:id,"sage_user_password_confirmation").set(sage_user.password_confirmation)
    user.checkbox(:id, "sage_user_terms_of_service").click if sage_user.terms_of_service
  end  
  
  def user_fills_in_billing_info_form(user, attrs=nil)
    attrs ||= user.user
    sage_user = valid_sage_user(attrs)
    user.text_field(:id,"edit-first-name").set(sage_user.first_name)
    user.text_field(:id,"edit-last-name").set(sage_user.last_name)
    user.text_field(:id,"edit-address").set(sage_user.address)
    user.text_field(:id,"edit-city").set(sage_user.city)
    user.text_field(:id,"edit-zip-code").set(sage_user.zip_code)
    user.select_list(:id,"edit-country").select_value(sage_user.country.upcase)
    user.select_list(:id,"edit-state").select_value(sage_user.state)
    user.text_field(:id,"edit-phone-no").set(sage_user.phone)
    user.text_field(:id,"edit-email-address").set(sage_user.email)  
  end
  
  def assert_on_sam_signup_page(user, debug=false)
    $test_ui.agree('on sam signup page?', true) if debug
    assert user.button(:id, "register_button").exists?    
    assert user.text_field(:id,"sage_user_username").exists?    
  end
  
  def assert_on_bb_signup_page(user, debug=false)
    $test_ui.agree('on bb signup page?', true) if debug
    assert user.button(:id, "register_button").exists?    
    assert user.text_field(:id,"sage_user_username").exists?  
    assert_equal "Sign up for Billingboss", user.title, "The billing boss signup page title should be 'Sign up for Billingboss'"  
  end  
  
  def assert_on_free_tools_page(user, debug=false)
    $test_ui.agree('on free tools page?', true) if debug
    assert_equal "Free Business Tools – Sage Spark Small Business Resources",	@user.title,"The SageSpark free tools page title should be Free Business Tools – Sage Spark Small Business Resources"
  end
  
  def assert_on_sbb_bb_signup_page(user, debug=false)
    $test_ui.agree('on free tools billingboss signup page?', true) if debug
    assert_equal "Free Business Tools – Sage Spark Small Business Resources",	@user.title,"The SageSpark free tools page title should be Free Business Tools – Sage Spark Small Business Resources"
    assert_match "/tools-services/free-billing", user.url
    assert user.contains_text('Billing Boss')
    assert user.contains_text('Your Cart')
    assert user.button(:value, /sign ?up now/i).exists?
  end
  
  def assert_on_sage_spark_authentication_page(user, debug=false)
    $test_ui.agree('on sage spark authentication page?', true) if debug
    assert_equal "Sage Spark Authentication",	@user.title,"The Sage Spark Authentication page title should be Sage Spark Authentication"
  end
  
  def assert_on_billing_info_page(user, debug=false)
    $test_ui.agree('on billing info page?', true) if debug
    assert_equal "Billing Information | Sage Spark",	@user.title,"The Billing Info page title should be Billing Information | Sage Spark"
  end 
  
  def assert_on_free_tool_summary_page(user, debug=false)
    $test_ui.agree('on free tool summary page?', true) if debug
    assert_equal "Free Tool Summary Page | Sage Spark",	@user.title,"The free tool summary page title should be Free Tool Summary Page | Sage Spark"
  end  
  
  def assert_on_step3_page(user, debug=false)
    $test_ui.agree('on step 3 page?', true) if debug  
    assert_no_warning(user, debug)
    assert_equal "Step 3 - Finished! | Sage Spark",	@user.title,"The Step 3 page title should be Step 3 - Finished! | Sage Spark"      
  end  
  
  def assert_on_my_tools_and_services_page(user, debug=false)
    $test_ui.agree('on my tools and services page?', true) if debug  
    assert_no_warning(user, debug)
    assert_equal "My Tools & Services | Sage Spark",	@user.title,"The My Tools & Services page title should be My Tools & Services | Sage Spark"      
  end  
  
  def assert_logged_in_on_sbb(user, debug=false)
    exit unless $test_ui.agree('check logged in?', true) if debug
    assert user.contains_text("Welcome,"), "page should have 'Welcome #{user.user.username}' message"
    assert user.link(:text, "#{user.user.username.capitalize}").exist?, "page should have user's name as a link"
    assert_no_warning(user, debug)
  end
  
  def deny_logged_in_on_sbb(user, debug=false)
    exit unless $test_ui.agree('check logged in?', true) if debug
    deny user.contains_text("Welcome,")
    assert_no_warning(user, debug)
  end
  
  def assert_logged_in_on_bb(user, debug=false)
    exit unless $test_ui.agree('check logged in?', true) if debug
    assert user.link(:id, "logout-link").exist?, "user is not logged in because logout link doesn't exist"
    assert_no_warning(user, debug)
  end  
  
  def deny_logged_in_on_bb(user, debug=false)
    exit unless $test_ui.agree('check logged in?', true) if debug
    deny user.link(:id, "logout-link").exist?, "user should not be logged in, but logout link exists"
    assert_no_warning(user, debug)
  end  
  
  def assert_on_my_sage_on_sbb(user, type, debug=false)
    exit unless $test_ui.agree('assert on my_sage?', true) if debug
    case type
    when :business
      # /node/number/edit/number
      assert user.link(:href, /\/node\/\d+\/edit\/\d+/).exists?
      assert user.contains_text(/your business information/i), "there was no business listing link"
    when :personal
      # /node/13034/edit/1 
      assert user.link(:href, /\/node\/\d+\/edit\/\d+/).exists?
      assert user.contains_text(/pitch your profile/i), "did not find Pitch your profile on page"
    end
    assert user.contains_text("My Sage"), "did not find 'My Sage' on page"
    assert_no_warning(user, debug)
  end

  def assert_bb_login_link_points_to_sagespark(user, debug=false)
    login_link = user.link(:id, "login-link")
    assert login_link.exists?, "should be a login link on the page"
    assert_match Sage::Test::Server.sagebusinessbuilder.url, login_link.href, "login link should be to a sagespark page"
  end

  def assert_bb_signup_link_points_to_sagespark(user, debug=false)
    signup_link = user.link(:id, "signup-link")
    assert signup_link.exists?, "should be a signup link on the page"
    assert_match Sage::Test::Server.sagebusinessbuilder.url, signup_link.href, "login link should be to a sagespark page"
  end
  
  def assert_knownlocally_theme(user, debug=false)
    exit unless $test_ui.agree('about to assert knownlocally?', true) if debug
    assert_equal 'knownlocally', user.js_eval("body.id")
  end
    
  def random_new_sage_user
    valid_sage_user
  end
  
  def valid_sage_user(attrs={})
    OpenStruct.new(valid_sage_user_attrs(attrs))
  end

  def valid_sage_user_attrs(attrs={})
    attrs = always_a_hash(attrs)
    alphabet = 'abcdefghijklmnopqrstuvwxyz'
    username = attrs[:username] || Babel.random_username.downcase + alphabet[rand(26),1] + alphabet[rand(26),1] + alphabet[rand(26),1] + alphabet[rand(26),1]

    attrs = {
      :username => username,
      :email => "#{username}@billingboss.com",
      :password => "test123",
      :password_confirmation => 'test123',
      :terms_of_service => true
    }.merge(attrs)    
  end
  
  def random_name_and_address
    {
      :first_name => Babel.random_username.gsub(/[0-9]/, ''),
      :last_name => Babel.random_surname.gsub(/[0-9]/, ''),
      :address => "13888 Wireless Way",
      :city => "Richmond",
      :state => "BC",
      :country => "ca",
      :zip_code => "V6V 6V6",
      :phone => "123-123-1234"
    }
  end
  
  def always_a_hash(attrs)
    attrs = case attrs
    when Hash
      attrs
    when OpenStruct
      attrs.to_h
    when ActiveRecord::Base
      attrs.attributes
    else
      attrs
    end
    attrs.with_indifferent_access
  end

  def assert_no_warning(user, debug=false)
    exit unless $test_ui.agree('page has warning. continue?', true) if debug && user.contains_text("user warning")      
    deny user.contains_text("user warning"), "page contained a warning message"
  end
  
  def assert_on_congratulations_popup(user, debug=false)
    exit unless $test_ui.agree('about to check for congratulations popup. continue?', true) if debug
    assert user.contains_text(/congratulations on creating your my sage account!/i)    
    assert user.link(:id, "TB_closeWindowButton").exists?
  end
  
  def extract_service_param_from_url(user, debug=false)
    require 'uri'
    uri = URI.parse user.url
    query = CGI.parse uri.query
    assert_not_nil query['service']
    assert_equal 1, query['service'].length
    query['service'].first
  end
  
  def click_choose_profile_link(user, profile, debug=false)
    @user.link(:id, "choose-#{profile}-profile-link").click
  end
end
