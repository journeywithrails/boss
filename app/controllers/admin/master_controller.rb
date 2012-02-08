class Admin::MasterController < ApplicationController

  prepend_before_filter CASClient::Frameworks::Rails::Filter  
  permit "master_admin"
  
  def index
  end
  
  def new    
  end
  
  def edit
    @user = User.find(:first, :conditions => {:id => params[:id]})
  end
  
  def update
    @user = User.find(:first, :conditions => {:id => params[:id]})
    update_admin_roles_for_user
    render :action => :index
  end
    
  def create
    @user = User.find(:first, :conditions => {:sage_username => params[:master][:login]})
    if @user.nil?
      flash[:notice] = "User not found"
      render :action => :new
    end
    update_admin_roles_for_user
    render :action => :index
  end
 
  def delete
    @user = User.find(:first, :conditions => {:id => params[:id]})
    if @user.nil?
      flash[:notice] = "User not found"
      render :action => :index
    else
      AdminManager.delete_generic_admin(@user)
      flash[:notice] = "Admin role removed from %{userid}" % {:userid => @user.sage_username}
      render :action => :index
    end
  end
  
  protected
  def update_admin_roles_for_user
    admin_roles.each do |ar|
      if params[:master][ar] == "1"
        add_admin_role_to_user( @user, ar )
      elsif params[:master][ar] == "0"
        remove_admin_role_from_user( @user, ar )
      end
    end
  end
  
end