module SamSupportHelper
  def self.included(base)
    base.send :helper_method, :signup_url if base.respond_to? :helper_method
    base.send :helper_method, :signup_for_sagespark_users_url if base.respond_to? :helper_method
    base.send :helper_method, :signup_for_new_users_url if base.respond_to? :helper_method
  end
  
  
  protected
  
  attr_accessor :signup_service_url
  
  # returns an url that points to Sageaccountmanager. If the parameter is a string, it is the service url.
  # The service url is where Sageaccountmanager will redirect back to after a successful signup.
  # The param can also be a hash, with :service_url as an option.
  # Other options are :portal_app, which defaults to billingboss, and :theme which defaults to nothing
  # these can be used to specify a Sageaccountmanager theme
  # If no service_url is specified, it will be login_url
  def signup_for_new_users_url(options={})
    RAILS_DEFAULT_LOGGER.debug("signup_url options: #{options.inspect}")
    
    case options
    when String
      service_url = options
      options = {}
    when Hash
      service_url = options.delete(:service_url)
    end

    theme = options.delete(:theme)
    portal_app = options.delete(:portal_app) || 'billingboss'
    
    service_url = signup_service_url if service_url.nil? unless signup_service_url.nil?
    service_url = first_profile_edit_url if service_url.nil?

    locale = options.delete(:locale)
    if locale.nil? && defined? GettextLocalize
      unless GettextLocalize.locale.nil?
        RAILS_DEFAULT_LOGGER.debug("GettextLocalize.locale: #{GettextLocalize.locale.inspect}")
        locale = GettextLocalize.locale.to_s
      end
    end
    
    locale ||= 'en'
    params = ["locale=#{locale}"]
    options[:locale] = locale # set locale back in options, so that it ends up in service url as well.
    
    if options.delete(:send_params)
      params << "sp=1"
    end
    RAILS_DEFAULT_LOGGER.debug("options: #{options.inspect}")
    RAILS_DEFAULT_LOGGER.debug("service_url: #{service_url.inspect}")
    unless options.empty? || service_url.blank?
      service_url += ((service_url.include? ??) ? '&' : '?')
      options.each do |k, v|
        unless k.blank? || v.blank?
          service_url += "#{k}=#{CGI.escape(v)}&"
        end
      end
      service_url.chomp!("&")
    end
    
    params << ("service=" + CGI.escape(service_url)) unless service_url.blank?
    params = params.join("&")
    
    params = "?" + params unless params.blank?
    
    signup = '/'
    unless portal_app.blank?
      signup += portal_app + '/'
      unless theme.blank?
        signup += theme + '/'
      end
    end
    signup += 'signup/new' unless signup == '/'
    signup = ::AppConfig.sageaccountmanager.url + signup + params
    signup
  end  
  
  def signup_url(options={})
    signup_for_new_users_url(options)
  end
  
  # When someone comes to BB who is a logged-in Sagespark user, but has no BB User yet
  # the signup & login links direct them to the BB info page on Sagespark
  def signup_for_sagespark_users_url(options={})
    raise "signup_for_sagespark_users_url: could not find a sage_username" unless has_sage_user?    
    raise "signup_for_sagespark_users_url: this user has a BB user already" if has_billingboss_user?
    ::AppConfig.sagebusinessbuilder.url + ::AppConfig.sagebusinessbuilder.bb_signup
  end

end