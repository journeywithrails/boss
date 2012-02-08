class AccessController < ApplicationController

  prepend_before_filter CASClient::Frameworks::Rails::Filter, :only => 'toggle_access'
  
  def access
    ak = AccessKey.find_by_key(params[:access])
    
    if ak.nil?
     render :file => "#{RAILS_ROOT}/public/404.html",
      :status => 404
    else
      if ak.use?
        keyable_type = ak.keyable_type
        case keyable_type
        when 'Invoice'
          redirect_to :controller => keyable_type.tableize, :action => 'display_invoice', :id=>ak.key
        when 'Invitation'
          #For Single Table Inheritance, point to the correct invitation controller
          controller = ak.keyable.class.name.tableize
          redirect_to :controller => controller, :action => 'display_invitation', :id=>ak.key
        end
      else
       render :file => "#{RAILS_ROOT}/public/404.html",
        :status => 404
      end
    end
  end
  
  def toggle_access
    ak = AccessKey.find(params[:id])
    ak.toggle_uses!
    
    redirect_to :back
  end
  
end
