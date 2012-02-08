require File.dirname(__FILE__) + '/../../test_helper'

class TestController < ApplicationController
end

class SamSupportHelperTest < HelperTestCase

  include SamSupportHelper


  def setup
    super
    @controller = TestController.new
  end
  
  def test_signup_url_adds_locale_to_signup_url_and_to_service_url
    GettextLocalize.set_locale('bo_BB')
    url = signup_url("http://test.host.com/login") # URI doesn't like just test.host :(
    signup_url_params, service_url, service_url_params = decompose_url(url)

    assert signup_url_params.has_key?(:locale), "url should have locale param"
    assert_equal 'bo_BB', signup_url_params[:locale].flatten.to_s, "url locale param should have come from GettextLocalize"
    assert service_url_params.has_key?(:locale), "url should have locale param"
    assert_equal 'bo_BB', service_url_params[:locale].flatten.to_s, "url locale param should have come from GettextLocalize"
  end
  
  def test_signup_url_should_allow_override_locale
    GettextLocalize.set_locale('bo_BB')
    url = signup_url(:service_url => "http://test.host.com/login", :locale => 'ma_RY') # URI doesn't like just test.host :(
    signup_url_params, service_url, service_url_params = decompose_url(url)

    assert signup_url_params.has_key?(:locale), "url should have locale param"
    assert_equal 'ma_RY', signup_url_params[:locale].flatten.to_s, "url locale param should have come from GettextLocalize"
    assert service_url_params.has_key?(:locale), "url should have locale param"
    assert_equal 'ma_RY', service_url_params[:locale].flatten.to_s, "url locale param should have come from GettextLocalize"
  end

  def test_signup_for_sagespark_users_url_raises_when_there_is_no_sage_user
    @controller.expects(:session).at_least_once.returns({})
    assert_raises RuntimeError, "signup_for_sagespark_users_url: could not find a sage_username" do
      @controller.signup_for_sagespark_users_url
    end
  end

  def test_signup_for_sagespark_users_url_raises_when_there_is_a_bb_user
    @controller.expects(:current_user).at_least_once.returns(users(:basic_user))
    @controller.expects(:session).at_least_once.returns(:sage_user => "basic_user")
    assert_raises RuntimeError, "signup_for_sagespark_users_url: this user has a BB user already" do
      @controller.signup_for_sagespark_users_url
    end
  end
  
  def test_signup_for_sagespark_users_url_points_to_sagespark
    @controller.expects(:current_user).at_least_once.returns(nil)
    @controller.expects(:session).at_least_once.returns(:sage_user => "bob_the_user")
    assert @controller.signup_for_sagespark_users_url.include?(::AppConfig.sagebusinessbuilder.url)
    assert @controller.signup_for_sagespark_users_url.include?(::AppConfig.sagebusinessbuilder.bb_signup)
  end
  
  def test_signup_url_with_no_service_url
    url = signup_url(:service_url => false)
    assert url.include?("?")
    signup_url_params, service_url, service_url_params = decompose_url(url, false)
    assert signup_url_params.has_key?("locale"), "signup url should have a locale"
  end
  
  def test_controller_can_override_default_service_url
    @controller.stubs(:first_profile_edit_url).returns("default-service")
    deny @controller.signup_url =~ /custom-service/, "before setting signup_service_url, signup_url should NOT contain custom service_url"
    @controller.send(:signup_service_url=, "custom-service")
    url = @controller.signup_url
    assert_match(/custom-service/, url, "after setting signup_service_url, signup_url should contain custom service_url")
  end
  
  def test_signup_url_includes_extra_param
    GettextLocalize.stubs(:locale).returns(nil)
    url = signup_url(:service_url => "http://test.host.com/login", :email => "bob@billingboss.com")
    signup_url_params, service_url, service_url_params = decompose_url(url)

    assert signup_url_params.has_key?(:locale), "url should have locale param"
    assert_equal 'en', signup_url_params[:locale].flatten.to_s, "url locale param value should be the default en"
    assert service_url_params.has_key?(:locale), "service url should have locale param"
    assert_equal 'en', service_url_params[:locale].flatten.to_s, "service url locale param value should be the default en"
    assert service_url_params.has_key?(:email), "url should have email param"
    assert_equal 'bob@billingboss.com', service_url_params[:email].flatten.to_s, "email param value should be what was passed in"
  end

  def test_signup_url_includes_multiple_extra_params
    GettextLocalize.stubs(:locale).returns(nil)
    url = signup_url(:service_url => "http://test.host.com/login", :email => "bob@billingboss.com", :other => "another")
    signup_url_params, service_url, service_url_params = decompose_url(url)

    assert signup_url_params.has_key?(:locale), "url should have locale param"
    assert_equal 'en', signup_url_params[:locale].flatten.to_s, "url locale param value should be the default en"
    assert service_url_params.has_key?(:locale), "service url should have locale param"
    assert_equal 'en', service_url_params[:locale].flatten.to_s, "service url locale param value should be the default en"
    assert service_url_params.has_key?(:email), "url should have email param"
    assert_equal 'bob@billingboss.com', service_url_params[:email].flatten.to_s, "email param value should be what was passed in"
    assert service_url_params.has_key?(:other), "url should have other param"
    assert_equal 'another', service_url_params[:other].flatten.to_s, "other param value should be what was passed in"
  end
  
  def test_signup_url_ignores_blank_valued_extra_params
    GettextLocalize.stubs(:locale).returns(nil)
    url = signup_url(:service_url => "http://test.host.com/login", :email => "bob@billingboss.com", :other => "another", :nil => nil, :blank => '', nil => 'bob')
    signup_url_params, service_url, service_url_params = decompose_url(url)

    assert service_url_params.has_key?(:email), "url should have email param"
    assert_equal 'bob@billingboss.com', service_url_params[:email].flatten.to_s, "email param value should be what was passed in"
    assert service_url_params.has_key?(:other), "url should have other param"
    assert_equal 'another', service_url_params[:other].flatten.to_s, "other param value should be what was passed in"
    
    deny service_url_params.has_key?(nil), "extra param with key nil should have been ignored"
    deny service_url_params.has_key?(:nil), "extra param with nil value should have been ignored"
    deny service_url_params.has_key?(:blank), "extra param with blank value should have been ignored"
  end
  
  def decompose_url(url, asserts_service=true)
    service_url_params = nil
    service_url = nil
    signup_url_params = url_to_params(url)
    deny signup_url_params.has_key?(nil), "signup url should not have any nil params"
    deny signup_url_params.any?{|k,v| v.blank?}, "signup url should not have any params with blank values"
    if asserts_service
      assert signup_url_params.has_key?(:service), signup_url_params
    end
    # puts "signup_url_params[:service]: #{signup_url_params[:service].inspect}"
    service_url = signup_url_params[:service].flatten.to_s
    # puts "service_url: #{service_url.inspect}"
    unless service_url.blank?
      service_url_params = url_to_params(service_url)
      deny service_url_params.has_key?(nil), "service url should not have any nil params"
      deny service_url_params.any?{|k,v| v.blank?}, "service url should not have any params with blank values"
    end
    return [signup_url_params, service_url, service_url_params]
  end
end
