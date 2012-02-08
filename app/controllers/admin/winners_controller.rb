
class Admin::WinnersController < ApplicationController
 
  @@SIGNUP_TYPES = ["soho", "ssan"]
  
  prepend_before_filter CASClient::Frameworks::Rails::Filter  
  permit "master_admin or winners_admin"
  
  def index
    prepare_winners_data
    render :action => "list"
  end

  def show
    prepare_winners_data
    render :action => "list"
  end
  
  def list
    prepare_winners_data
  end

  def new
  end

  def create

    @signup_type = params[:signup_type]
    if request.post? && valid_type?(@signup_type)
      begin
        Winner.transaction do
          Winner.delete_all({:signup_type => @signup_type})
          if params[:winners] && (params[:winners].size > 0)
            params[:winners].each do |p|
              w = Winner.new
              w.attributes = p[1]
              w.signup_type = @signup_type
              w.save!
            end
          end
        end
      rescue
      end
    end
    redirect_back
  end
  
  def destroy
    @id = params[:id]
    if !@id.blank?
      @w = Winner.find(@id)
      @w.destroy
    end
    redirect_back
  end
  
  def prepare_winners_data
    @signup_types = @@SIGNUP_TYPES
    @signup_type = params[:signup_type]
    @winners = Winner.find(:all, :conditions => {:signup_type => @signup_type})
  end
  
  def redirect_back
    redirect_to "/admin/winners?signup_type=#{@signup_type}"
  end
  
  def valid_type?(signup_type)
    @@SIGNUP_TYPES.include?(signup_type)
  end
  
end