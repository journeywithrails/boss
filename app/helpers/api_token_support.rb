module ApiTokenSupport
  def self.included(target)
    target.helper_method(:api_token?)
    target.helper_method(:api_token)
  end

  protected

  def api_token?    
    result = if defined?(@api_token)
      @api_token
    else
      session[:api_token_id]
    end
    RAILS_DEFAULT_LOGGER.debug("api_token? session[:api_token_id]: #{session[:api_token_id].inspect}  result: #{result.inspect}")
    result
  end

  def api_token
    if defined?(@api_token)
      @api_token
    elsif session[:api_token_id]
      @api_token = ApiToken.find_by_id(session[:api_token_id])
    else
      @api_token = nil
    end
  end

  def internal_or_external_layout(force_external = false)
    return @custom_layout if @custom_layout
    if api_token?
      "simply/#{ default_layout(force_external) }"
    else
      super
    end
  end

  def internal_layout
    raise Sage::BusinessLogic::Exception::AccessDeniedException unless logged_in? 
    if api_token?
      'simply/main'
    else
      super
    end
  end  

end
