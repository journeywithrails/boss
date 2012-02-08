class GlobalRescueController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter
  
  def index
   @custom_title  ="An error has occurred."
   
   if !logged_in?
     render :action => 'index_logged_out'
   end
  end

end