# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ServiceProviderController < ApplicationController
  #helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => 'ef977b6a847c53f5bea4512a32af9087'
  skip_before_filter :verify_authenticity_token
  
  def default_xml_format
    # Computers, not people, talk to the Service Provider, so
    # if the format is not specified by an extension in the URL, 
    # and the requestor is not a popular browser, default to XML.
    if request.env and request.env['HTTP_USER_AGENT'] and
      request.env['HTTP_USER_AGENT'].match( /Mozilla/) 
      return
    end
    if !params[:format]
      params[:format] = 'xml'
    end
  end
  
  def get_data_params
    # This method assigns the parameters relevant to the controller's model into @data_params.
    model_name = self.class.to_s.gsub(/sController/,'').downcase
    model_name = model_name.gsub(/^.*::/,'') #Remove leading namespace if the controller is namespaced.
    # if using nested Rails params, grab those
    if params[model_name.to_sym]
      @data_params = params[model_name.to_sym]
    # else use the flat params, ignoring those unrelated to the model data 
    else
      @data_params = params.clone
      ["action", "controller", "format"].each do |param|
        @data_params.delete(param)
      end
    end
  end
  
  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password| 
      user_name == ::AppConfig.service_provider.admin_user && password == ::AppConfig.service_provider.admin_password
    end
  end  
  
end
