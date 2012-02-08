module MobileSupport

  protected
  
  def detect_user_agent
    #always obey manual user override, regardless of their user agent
    if params[:mobile]

      session[:mobile_browser] = true if params[:mobile].to_s.downcase == "true"
      session[:mobile_browser] = false if params[:mobile].to_s.downcase == "false"

    #without an explicit param, set session according to user agent
    #this should only be called if session has NEVER been set before, 
    #or the users manual override will be forgotten on the next request
    elsif session[:mobile_browser].blank?
      if ::AppConfig.mobile_enabled and (request.user_agent.to_s.downcase.include?("mobile") or request.user_agent.to_s.include?("Android") or request.user_agent.to_s.include?("BlackBerry") or request.user_agent.to_s.include?("webOS"))
        session[:mobile_browser] = true
  #      puts "MOBILE REQUEST"
      end
    end
  end
  
  #render_with_mobile_support should be used to replace an explicit render command
  #use mobile_layout instead of layout param because layout param should be preserved in case
  #the normal render() is called
  def render_with_mobile_support(params=nil)
    if session[:mobile_browser]
      return render_mobile(params)
    else
      return render(params)
    end
  end
    
  #render_mobile can be called directly when there is no explicit render statement
  #or when the statement is retained as a separate action in the caller based on a condition
  #i.e. it cannot REPLACE a render statement. for that, use render_with_mobile_support instead
  def render_mobile(params=nil)
    #if mobile browser is detected, render mobile layout
    #unless specified otherwise by caller, it is assumed to be at views/controller_name/mobile/action_name.html.erb
    action = params[:action] unless !params || !params[:action]
    controller = params[:controller] unless !params || !params[:controller]
    mobile_layout = params[:mobile_layout] unless !params || !params[:mobile_layout]
    
    action ||= action_name
    controller ||= controller_name
    layout ||= "mobile"
    
    if session[:mobile_browser]
      params[:layout] = nil
      return render(:template => "/#{controller}/mobile/#{action}", :layout => mobile_layout)
    else
      return false
    end
  end

  def self.included(base)
    base.send :helper_method, :render_mobile
    base.send :before_filter, :detect_user_agent
  end

end
