module Localizer

  def init_language
    RAILS_DEFAULT_LOGGER.debug("init_language. params[:locale]: #{params[:locale].inspect}")
    
    if !params[:locale].blank?
      RAILS_DEFAULT_LOGGER.debug("calling set_locale_by_param")      
      change_language!(params[:locale])
      save_language_to_cookie(params[:locale])
    elsif (cookies["lang"].nil? or cookies["lang"].empty?)
      RAILS_DEFAULT_LOGGER.debug("calling set_language_from_http_header")      
      set_language_from_http_header
    else
      RAILS_DEFAULT_LOGGER.debug("setting locale from cookie")
      
      GettextLocalize.set_locale(cookies["lang"])
    end
  end

  def change_language!(language)
    available_language?(language) ? (GettextLocalize.set_locale(language)) : (GettextLocalize.set_locale(AppConfig.default_language))
    save_language_to_cookie(language)
  end
  
  def save_language_to_cookie(language)
    RAILS_DEFAULT_LOGGER.debug("save_language_to_cookie #{language}")   
    cookies["lang"] = language
  end
  
  def set_language_from_cookie
    RAILS_DEFAULT_LOGGER.debug("set_language_from_cookie")    
    unless (cookies["lang"].nil? or cookies["lang"].empty?)
      if available_language?(cookies["lang"])
        GettextLocalize.set_locale(cookies["lang"])
      else
        GettextLocalize.set_locale(AppConfig.default_language)
      end
    end
  end
  
  def available_language?(lang)
    ((lang.length == 2) &&
        AppConfig.available_languages.include?(lang)) ||
      AppConfig.available_languages.include?(lang[0,2])
  end
    
  def set_language_from_http_header
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
    @language = ""
    unless accept_language.nil?
      @language = accept_language[0,2] unless accept_language.length < 2
    end
    change_language!(@language)
  end
  
end