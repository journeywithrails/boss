module SSO
  def self.add_service(url, service_url)
    out = url
    if out['?']
      out += '&' unless out[-1..-1] == '&'
    else
      out += '?'
    end
    out += "service=#{CGI.escape(service_url)}"
  end

  module CAS
    def self.login_url(for_service=nil, absolute = true, secure=true)
      url = absolute ? (secure ? Sage::Test::Server.cas_server_sage.secure_url : Sage::Test::Server.cas_server_sage.url) : Sage::Test::Server.cas_server_sage.base_path
      url += "/login"
      url = SSO.add_service(url, for_service) unless for_service.nil?
      url
    end
    
    def self.secure_login_url(for_service=nil, absolute=true)
      self.login_url(for_service, absolute, true)
    end
  end
  
  module SAM
    def self.signup_url(for_app=:sbb, for_service=nil)
      app = case for_app.to_sym
      when :sbb
        'sagespark'
      when :bb
        'billingboss'
      end
      url = Sage::Test::Server.sageaccountmanager.url + "/" + app + "/signup/new"
      url = SSO.add_service(url, for_service) unless for_service.nil?
      url
    end
    
    def self.forgot_password_url(for_app=:sbb, for_service=nil)
      app = case for_app.to_sym
      when :sbb
        '/sagespark'
      when :bb
        '/billingboss'
      else
        ''
      end
      url = Sage::Test::Server.sageaccountmanager.url + "#{app}/reset_password"
      url = SSO.add_service(url, for_service) unless for_service.nil?
      url
    end
    
    def self.prepare(force=false)
      # $log_on = true
      if force || !@did_prepare
        puts "running sageaccountmanager sso:tests:prepare" if $log_on
        Sage::Test::Server.sageaccountmanager.rake "sso:tests:prepare"
        @did_prepare=true
      end
    end
  end

  module SBB
    def self.add_registered_domain(username, domain)
      Sage::Test::Server.sagebusinessbuilder.rake "sso:tests:adddomain domain=#{domain} username=#{username}"
    end
    
    def self.prepare(force=false)
      if force || !@did_prepare
        puts "running sagebusinessbuilder sso:tests:prepare" if $log_on
        Sage::Test::Server.sagebusinessbuilder.rake "sso:tests:prepare"
        @did_prepare = true
      end
    end
    
    def self.special_landing_page
      "tools-services/free-billing/billingboss-welcome"
    end
    
  end
  
  module Proveng
    def self.prepare(force=false)
      # $log_on = true
      if force || !@did_prepare
        puts "running proveng db:test:prepare" if $log_on
        Sage::Test::Server.proveng.rake "db:test:prepare"
        Sage::Test::Server.proveng.rake "db:fixtures:load"
        @did_prepare=true
      end
    end
  end  

  module CSP
    def self.prepare(force=false)
      # $log_on = true
      if force || !@did_prepare
        puts "running csp db:test:prepare" if $log_on
        Sage::Test::Server.csp.rake "db:test:prepare"
        Sage::Test::Server.proveng.rake "db:fixtures:load"
        @did_prepare=true
      end
    end
  end  
end
