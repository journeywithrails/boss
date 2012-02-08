module Kernel
  def singleton_class
    class << self; self; end
  end
end


module CasTestHelper

  def login_as(user)
    if user
      # @request.session[:user] = users(user).id
      # @request.session[:sage_user] = users(user).sage_username
      # CASClient::Frameworks::Rails::Filter.stubs(:filter).returns(true)
      # CASClient::Frameworks::Rails::GatewayFilter.stubs(:filter).returns(true)
      stub_cas_logged_in users(user)
    else
      logout
    end
  end

  def logout
    @request.session[:user] = nil
    @request.session[:sage_user] = nil
    @controller.instance_variable_set(:@current_user, nil)
    stub_cas_logged_out
  end
    
  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? "Basic #{Base64.encode64("#{users(user).sage_username}:test")}" : nil
  end

  
  def stub_cas_check_status
    unless CASClient::Frameworks::Rails::Filter.config.has_key?(:check_cas_status)
      CASClient::Frameworks::Rails::Filter.config[:original_check_cas_status] = CASClient::Frameworks::Rails::Filter.config[:check_cas_status]
    end
    CASClient::Frameworks::Rails::Filter.config[:check_cas_status] = false
  end
  
  def assert_redirected_to_cas_login
    assert_response :redirect
    assert_match(Regexp.new(CASClient::Frameworks::Rails::Filter.client.login_url), redirect_to_url)
  end

  def assert_cas_service_url_matches path
    uri = URI.parse(redirect_to_url)
    h = CGI.parse(uri.query)
    assert_not_nil h['service']
    assert_match path, h['service'].to_s
  end

  def stub_cas_logged_in(user, source='billingboss')
    unstub_cas
    stub_cas_check_status
    RAILS_DEFAULT_LOGGER.debug "stub_cas_logged_in with #{user} (#{user.sage_username})" 
    CASClient::Frameworks::Rails::Filter.send :define_method, :handle_authentication do
      RAILS_DEFAULT_LOGGER.debug "in stub for logged_in" 
      RAILS_DEFAULT_LOGGER.debug "user is: #{user}" 
      controller.session[:sage_user] = user.sage_username
      controller.session[:user] = user.id 
      controller.session[:cas_extra_attributes] = {:username => user.sage_username, :email => user.email, :source => source}.with_indifferent_access
      return (returns_url? ? service_url : true)
    end
  end

  # hit this right before you want to test a first login
  def stub_cas_first_login(pending_sage_user, pending_sage_user_email, source='billingboss')
    unstub_cas
    stub_cas_check_status
    RAILS_DEFAULT_LOGGER.debug("stubbing for first_login. pending_sage_user: #{pending_sage_user}  pending_sage_user_email: #{pending_sage_user_email.inspect}")  
    CASClient::Frameworks::Rails::Filter.send :define_method, :handle_authentication do
      RAILS_DEFAULT_LOGGER.debug "in stub for first_login. pending_sage_user: #{pending_sage_user}  pending_sage_user_email: #{pending_sage_user_email.inspect}"  
      controller.session[:sage_user] = pending_sage_user
      controller.session[:cas_extra_attributes] = {:username => pending_sage_user, :email => pending_sage_user_email, :source => source}.with_indifferent_access      
      return (returns_url? ? service_url : true)
    end
  end
  
  def stub_cas_logged_out
    unstub_cas
    stub_cas_check_status
    RAILS_DEFAULT_LOGGER.debug "stubbing for logged out, with gateway"
    CASClient::Frameworks::Rails::Filter.send :define_method, :handle_authentication do
      RAILS_DEFAULT_LOGGER.debug "in stub for cas_logged_out" 
      if use_gatewaying?(controller)
        return (returns_url? ? service_url : true)
      else
        controller.send(:reset_session)
        controller.send(:redirect_to, '/access/denied')
        return (returns_url? ? '/access/denied' : false)
      end
    end
  end
  
  def unstub_cas
    RAILS_DEFAULT_LOGGER.debug "unstubbing cas"
    unless CASClient::Frameworks::Rails::Filter.config.has_key?(:check_cas_status)
      CASClient::Frameworks::Rails::Filter.config[:original_check_cas_status] = CASClient::Frameworks::Rails::Filter.config[:check_cas_status]
    end
    CASClient::Frameworks::Rails::Filter.config[:check_cas_status] = CASClient::Frameworks::Rails::Filter.config[:original_check_cas_status]
    if CASClient::Frameworks::Rails::Filter.method_defined?(:original_handle_authentication)
      CASClient::Frameworks::Rails::Filter.class_eval do
        alias :handle_authentication :original_handle_authentication
        undef :original_handle_authentication
      end
    end
    CASClient::Frameworks::Rails::Filter.class_eval do
      alias :original_handle_authentication :handle_authentication
    end
  end
end
