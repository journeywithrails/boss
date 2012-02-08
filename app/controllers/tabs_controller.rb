class TabsController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter
  def biller
    current_user.save_current_view :biller
    if current_user.profile.is_complete?
      flash.keep(:notice)
      redirect_to :action => 'overview', :controller => 'invoices'
    else
      flash[:notice] = _("Please take a moment to fill in your business information.")
      if (current_user.new_user)
        current_user.new_user = false
        redirect_to first_profile_edit_path
      else
        redirect_to :action => 'edit', :controller => 'profiles'      
      end
    end
  end

  def bookkeeper
    flash.keep(:notice)
    current_user.save_current_view :bookkeeper
    redirect_to :action => 'index', :controller => 'bookkeeping_clients'    
  end
  
  def admin
    flash.keep(:notice)
    current_user.save_current_view :admin
    redirect_to "/admin/overview/index"
  end

end
