
class Admin::FeedbackController < ApplicationController
  helper FeedbackHelper
  
  prepend_before_filter CASClient::Frameworks::Rails::Filter  
  permit "master_admin or feedback_admin"
  
  def index
    prepare_feedback_data
    render :action => "list"
  end
  
  def list
    prepare_feedback_data
  end

  def show
    prepare_feedback_data
    render :action => "list"

  end

  def edit
    @f = Feedback.find(params[:id]) unless params[:id].blank?
  end
  
  def update
    @helper = ApplicationHelper
#    email_reply = params[:feedback][:email_reply]
#    params[:feedback].delete("email_reply")
    @id = params[:feedback][:id]
    @f = Feedback.find(@id)
    if request.put?
      if !@id.blank?
      @f.response_text = params[:feedback][:response_text]
      @f.response_status = params[:feedback][:status]
      claim = params[:feedback][:claim]
      if claim == "Yes"
        @f.owned_by = current_user.id
      end
      if claim == "No" and @f.owned_by == current_user.id
        @f.owned_by = 0
      end
      @f.save!
      if params[:feedback][:email_reply] == "1"
        FeedbackMailer.deliver_feedback_response(@f.user_name, @f.user_email, @f.response_text, @f.text_to_send)
        @f.last_reply_mailed_at = DateTime.now
        @f.save!
      end
      end
    end
    redirect_to "/admin/feedback/#{@id}/edit"
  end
  
  def destroy
    @id = params[:id]
    @f = Feedback.find(@id)
    @f.destroy

    redirect_to('/admin/feedback/')
  end
  
  def filter
    if request.post?
      split_multi_params(params[:filters])
      @filters = OpenStruct.new(current_user.set_or_get_search!(:feedback, params[:filters]))
    end
    prepare_feedback_data
    render :action => "list"
  end
  
  protected
  
  def split_multi_params(multi_params, *keys)
    return if multi_params.nil?
    keys.each do |k|
      if multi_params[k] 
        multi_params[k] = multi_params[k].split(/[, ]+/)
      end
    end
  end
  
  def prepare_feedback_data
    setup_search_filters(:feedback)
    @filtered_feedback = []
    filtered_statuses = []
    filtered_owners = []
    if @filters.f_open == "1"
      filtered_statuses << "Open"
    end
    if @filters.f_in_review == "1"
      filtered_statuses << "In review"
    end
    if @filters.f_closed == "1"
      filtered_statuses << "Closed"
    end
    
    if @filters.order_by == "Earliest to latest"
      order_by = "ORDER BY updated_at ASC"
    elsif @filters.order_by == "Latest to earliest"
      order_by = "ORDER BY updated_at DESC"    
    end
    
    @filtered_feedback = []
    feedback = Feedback.find_by_sql("SELECT * FROM feedbacks #{order_by}")
    feedback.each do |f|
      if filtered_statuses.include?(f.response_status)
        if !f.owned_by.blank? and !(f.owned_by.to_s == "0")
          feedback_owner = User.find(f.owned_by).sage_username
        else
          feedback_owner = nil
        end
        
        if ((feedback_owner.blank?) and (@filters.f_nobody == "1"))
          @filtered_feedback << f
        elsif (feedback_owner == current_user.sage_username) and (@filters.f_me == "1")
          @filtered_feedback << f
        elsif !feedback_owner.blank? and (feedback_owner != current_user.sage_username) and (@filters.f_others == "1")
          @filtered_feedback << f
        end
      end
    end    
  end


end