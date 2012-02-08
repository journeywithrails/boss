require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < HelperTestCase

  class TestController < ApplicationController
    include ApplicationHelper
    def url_for(options={})
      options[:action] ||= 'noop'
      options[:controller] ||= 'dummy'
      "#{options[:controller]}/#{options[:action]}"
    end
    
    def link_to(name, options = {}, html_options = nil)
      "#{name}: #{options.to_s}"
    end
  end

  def setup
    super
    @controller = TestController.new
  end
  
  def test_link_to_signup_links_to_sam_when_no_sage_user
    @controller.expects(:session).at_least_once.returns({})
    assert @controller.link_to_signup.include?(::AppConfig.sageaccountmanager.url)
    deny @controller.link_to_signup.include?(::AppConfig.sagebusinessbuilder.url)
  end

  def test_link_to_signup_links_to_sam_when_there_is_a_sage_user_and_a_bb_user
    @controller.expects(:current_user).at_least_once.returns(users(:basic_user))
    @controller.expects(:session).at_least_once.returns(:sage_user => "basic_user")
    assert @controller.link_to_signup.include?(::AppConfig.sageaccountmanager.url)
    deny @controller.link_to_signup.include?(::AppConfig.sagebusinessbuilder.url)
  end

  def test_link_to_signup_links_to_sbb_when_there_is_sage_user_and_no_bb_user
    @controller.expects(:current_user).at_least_once.returns(nil)
    @controller.expects(:session).at_least_once.returns(:sage_user => "bob_not_a_user")
    assert @controller.link_to_signup.include?(::AppConfig.sagebusinessbuilder.url)
    deny @controller.link_to_signup.include?(::AppConfig.sageaccountmanager.url)
  end  
end