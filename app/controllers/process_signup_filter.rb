class ProcessSignupFilter
  class << self
    def filter(controller)
      if controller.session[:heard_from].blank?
        controller.session[:heard_from] = "fr_canada_post" if controller.params[:r_id] == "10"
      end      
      [:referral_code, :signup_type].each do |p|
          controller.session[p] = controller.params[p] unless controller.params[p].blank?
      end
      if !User.valid_signup_type?(controller.session[:signup_type])
        if controller.logged_in? and !controller.current_user.signup_type.blank?
          controller.session[:signup_type] = controller.current_user.signup_type
        else
          controller.session[:signup_type] = User.DefaultSignupType
        end
      end
      return true
    end
  end
end

