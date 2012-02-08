require File.dirname(__FILE__) + '/test_helper'

class RubycasClientTest < Test::Unit::TestCase
  context "a configured rubycas client" do
    setup do
      CASClient::Frameworks::Rails::Filter.reset!
      class MockController
        def bobs_locale_finder
          "bo_BB"
        end
        
        def user_prefill_with_bob
          "bob"
        end
        
        def session
          {}
        end
      end
      
      def mock_controller
        MockController.new
      end
      
      def default_config(opts={})
        {
          :cas_base_url => 'https://test.rubycasclient.com/cas',
          :logger => CASClient::Logger.new(File.dirname(__FILE__) + '/../log/cas.log')
        }.merge(opts)
      end
    end
    
    should "add locale to url" do
      client = CASClient::Client.new(default_config)
      login_url = client.add_service_to_login_url("http://some.app.com/service")
      url = client.add_locale_to_url(login_url,'bo_BB')
      assert_equal "https://test.rubycasclient.com/cas/login?service=http%3A%2F%2Fsome.app.com%2Fservice&locale=bo_BB", url
    end
  
    context "with a rails filter" do
    
      should "have a localize setting" do
        assert !CASClient::Frameworks::Rails::Filter.new(mock_controller).add_locale?
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :add_locale => true
        ))
        cas_filter = CASClient::Frameworks::Rails::Filter.new(mock_controller)
        assert cas_filter.add_locale?
      end
      
      should "have a locale_callback setting" do
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :add_locale => true,
          :locale_callback => :bobs_locale_finder
        ))
        assert_equal :bobs_locale_finder, CASClient::Frameworks::Rails::Filter.locale_callback
      end
      
      should "add locale to login_url when redirecting to cas for authentication" do
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :add_locale => true,
          :locale_callback => :bobs_locale_finder
        ))
        instance = CASClient::Frameworks::Rails::Filter.new(mock_controller)
        instance.do_redirect = false
        instance.returning = :url
        instance.service_url = "http://some.app.com/service"
        redirect_url = instance.redirect_to_cas_for_authentication
        assert_equal "https://test.rubycasclient.com/cas/login?service=http%3A%2F%2Fsome.app.com%2Fservice&locale=bo_BB", redirect_url
      end
      
      should "have a user_prefill setting" do
        assert !CASClient::Frameworks::Rails::Filter.new(mock_controller).user_prefill?
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :user_prefill => true
        ))
        cas_filter = CASClient::Frameworks::Rails::Filter.new(mock_controller)
        assert cas_filter.user_prefill?
      end
      
      should "have a user_prefill_callback setting" do
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :user_prefill => true,
          :user_prefill_callback => :user_prefill_with_bob
        ))
        assert_equal :user_prefill_with_bob, CASClient::Frameworks::Rails::Filter.user_prefill_callback
      end
      
      should "add user_prefill to login_url when redirecting to cas for authentication" do
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :user_prefill => true,
          :user_prefill_callback => :user_prefill_with_bob
        ))
        instance = CASClient::Frameworks::Rails::Filter.new(mock_controller)
        instance.do_redirect = false
        instance.returning = :url
        instance.service_url = "http://some.app.com/service"
        redirect_url = instance.redirect_to_cas_for_authentication
        assert_equal "https://test.rubycasclient.com/cas/login?service=http%3A%2F%2Fsome.app.com%2Fservice&cas_user_prefill=bob", redirect_url
      end
      
      should "have a check_cas_status setting with default false" do
        assert !CASClient::Frameworks::Rails::Filter.new(mock_controller).check_cas_status?
        CASClient::Frameworks::Rails::Filter.configure( default_config(
          :check_cas_status => true
        ))
        cas_filter = CASClient::Frameworks::Rails::Filter.new(mock_controller)
        assert cas_filter.check_cas_status?
      end
    end
  end
  
end
