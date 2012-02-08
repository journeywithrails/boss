require 'admin/feedback_controller'
class FeedbackController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter
  caches_page :index
  #do not require login for feedback
  #permit "feedback_admin", :except => [:index, :new, :create] 
  
  def index
    new
  end
  
  def new
    render_with_a_layout("new", "external_main")    
  end
  
  def create
    if request.post?
      @feedback = Feedback.new
      @feedback.user_name = params[:feedback][:user_name]
      @feedback.user_email = params[:feedback][:user_email]
      @feedback.text_to_send = params[:feedback][:text_to_send]
      if @feedback.valid?
        @feedback.save!
        
        msg = params[:feedback][:text_to_send]
        usr_name = params[:feedback][:user_name]
        usr_email = params[:feedback][:user_email]    
        
        if (msg.length > 0) and ::AppConfig.mail_feedback
           if (logged_in?)
             FeedbackMailer.deliver_feedback(msg, current_user.sage_username, usr_name)                  
           else
             FeedbackMailer.deliver_feedback(msg, usr_email, usr_name)
           end
        end 
        render_with_a_layout("accepted", "external_main")
      else
        new   
      end
    else
      redirect_to "/feedback"
    end

  end

end
