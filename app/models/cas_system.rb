# Helpers for integrating with CAS, via the rubycas client plugin (see CASClient::Frameworks::Rails::Filter)
# 
# RADAR: current Sage-specific coupling, and how to remove it. Ideally this module should
# be split into two, one for managing coupling of rubycasclient to generic rails
# app users, and one for managing everything sage-specific about that
# 
# 1. Coupled to ApiToken. 
#     - in +current_user+. Could be removed by adding a +current_user_changed+ hook
#     - in +cas_service_url+. Could be removed by adding a +decorate_cas_service_url+ hook
#     - in +create_user_for_cas_user+. (see below)
# 
# 2. +create_user_for_cas_user+: This method contains a bunch of sage-specific stuff and 
#     should be moved to a hook that cas_system expects to be present. In particular it 
#     manages a bunch of non-cas decorating of user object from session variables.
# 
# 3. Uses sage_user as the CAS username. This could be made configurable, the same as 
#     rubycas filter does
module CasSystem
  # Inclusion hook to make functions available to views
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?, :cas_service_url, :current_action_service_url, :has_sage_user?, :has_billingboss_user?
  end

  attr_accessor :web_service_user

  # Figures out who the current logged in user is, if any, returning a User object.
  # The connection with CAS user is via +session[:sage_user]+, which corresponds to
  # User#sage_username. When the current user changes, any existing ApiToken also
  # has its current_user changed. Since users can log into CAS with their email,
  # after finding the current_user, session[:sage_user] is set back to 
  # +current_user.sage_username+.
  # 
  # RADAR: this method now has the side effect of setting the current user on 
  # api_token, but it is currently not called explicitly but as-needed.
  def current_user
    begin
      unless @current_user.is_a?(User)
        @current_user = if session[:sage_user]
            user = user_for_cas_user(session[:sage_user], session[:cas_extra_attributes])
            if user
              api_token.set_current_user(user) if api_token?
              # set session[:sage_user] to sage_username of the found user. This allows
              # login with email. Could also be done at the rubycas_client level, but
              # dual login is somewhat sage-specific
              session[:sage_user] = user.sage_username
            end

            user.nil? ? :false : user
          elsif self.web_service_user
            self.web_service_user
          elsif session[:web_service_user]
            User.find_by_sage_username(session[:web_service_user])
          else
            :false
          end
      end
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.warn "exception getting current user:\n#{e.inspect}"
      RAILS_DEFAULT_LOGGER.debug e.backtrace.join("\n")
      @current_user = :false
    end
    return @current_user
  end

  # true if there is a sage_user in the session (though such user is not necessarily
  # authenticated)
  def has_sage_user?
    ! session[:sage_user].blank?
  end
  
  # true if there is an active User object. Currently, an alias for logged_in?
  def has_billingboss_user?
    logged_in?
  end
  
  # true if current_user is a User object and its sage_username matches session[:sage_user]
  def logged_in?
    current_user.is_a?(User) && (current_user.sage_username == session[:sage_user])
  end
  
  # if this method returns true, cas_system will autmatically create a billingboss user
  # for a sage_user for which a billingboss user does not yet exist. This implementation
  # returns false, override to provide fine-grained control over whether a user gets
  # auto-created or not (for example, to auto_create a BB user only when the source
  # attribute of the sage_user contains billingboss).
  # 
  # +attrs+: the extra attributes of the sage_user as passed by CAS. in the current Sagespark
  # SSO setup, this will be +username+, +email+, +source+, +created_at+
  def auto_create_user?(attrs)
    false
  end
  
  # Store the given user in the session.
  def current_user=(new_user)
    @current_user = new_user
  end
  
  # call in actions to display the access denied page
  def access_denied
    respond_to do |accepts|
      accepts.html do
        store_location
        redirect_to access_denied_path
      end
      accepts.xml do
        headers["Status"]           = "Unauthorized"
        headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        render :text => "Couldn't authenticate you", :status => '401 Unauthorized'
      end
    end
    false
  end  
  
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location(location=nil)
    session[:return_to] = location || request.request_uri
  end
  
  # true if a location has been stored in the session using store_location
  def location_stored?
    !session[:return_to].nil?
  end
  
  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    #redirect_to(location_stored? ? session[:return_to] : default)
    # Use this line to drop the SSL connection after login.
    redirect_and_drop_SSL(clear_redirect_location(default))
  end

  # clears a location stored in the session using store_location, returning it
  def clear_redirect_location(default)
    location = location_stored? ? session[:return_to] : default
    session[:return_to] = nil
    location
  end
  
  # returns an absolute url to the current action. Does this simply by calling 
  # +cas_service_url+ with the current params
  def current_action_service_url(options={})
    cas_service_url(params.merge(options))
  end
  
  # constructs a service_url for use to pass to CAS or SAM. If there is an api_token?
  # adds it to the path by calling api_token.service_url_prefix
  def cas_service_url(options)
    #TODO: optimization point. this will get called twice on requests where we build a cas_service_url. but it seems that the cas filter is running before the before_init_gettext
    init_language 
    options = options.dup
    # cas filter will add locale
    options = options.reject{|k,v| %w{locale browsal simply_request}.include?(k.to_s)} if options.is_a?(Hash)
    
    url = url_for(options)
    if api_token?
      uri = URI.parse url
      uri.path = api_token.service_url_prefix  + uri.path unless uri.path.index(api_token.service_url_prefix) == 0
      url = uri.to_s
    end
    RAILS_DEFAULT_LOGGER.debug("cas_service_url: returning #{url}")
    url
  end
  
  # callback used by CASClient::Frameworks::Rails::Filter to add application locale
  # to CAS urls
  def cas_locale
    GettextLocalize.locale.to_s
  end
  
  # if +auto_create_user?+ is true, creates an application user for the current
  # sage_user, as well as handling heard_from, referral_code, signup_type
  # TODO: move this out of here, it does non CAS stuff
  def create_user_for_cas_user(username, extra_attributes)
    RAILS_DEFAULT_LOGGER.debug("create_user_for_cas_user #{username}")
    
    extra_attributes[:username] ||= username
    user = User.build_with_sage_username(extra_attributes)
    if user.new_user
      user.set_signup_type(session[:signup_type], api_token?)
      user.set_heard_from(session[:heard_from])
      user.credit_referral(session[:referral_code]) unless session[:referral_code].blank?
      session[:referral_code] = nil
      user.save!
    end
    RAILS_DEFAULT_LOGGER.debug("returning #{user.nil? ? nil : user.id}")    
    user
  end

  # finds an application user for the cas user. If none found, creates one if 
  # +auto_create_user?+ is true, by calling +create_user_for_cas_user+
  def user_for_cas_user(username, extra_attributes)
    RAILS_DEFAULT_LOGGER.debug("user_for_cas_user. extra_attributes: #{extra_attributes.inspect}")    
    username = extra_attributes[:username] unless extra_attributes[:username].blank?
    # look for a user with sage_username = to the username cas authenticated
    user = User.find_by_sage_username(username)
    # if can't find such a user, create a new user IFF auto_create_user is true (default is false)
    user = create_user_for_cas_user(username, extra_attributes) if user.nil? && auto_create_user?(extra_attributes)
    user
  end

  # wraps user_for_cas_user returning just id instead of object
  def user_id_for_cas_user(username, extra_attributes)
    user = user_for_cas_user(username, extra_attributes)
    user.nil? ? nil : user.id
  end

  private
  @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
  # gets BASIC auth info
  def get_auth_data
    auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
    auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
    return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
  end
end
