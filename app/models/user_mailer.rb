class UserMailer < ActionMailer::Base
  helper LocalizationHelper
  def signup_notification(user,is_new=true)
    setup_email(user)
    @is_new = is_new
    if (!user.signup_type.blank? and user.signup_type.downcase == "ssan") 
      @body[:rec] = _("customer")
    else
      @body[:rec] = _("friend")
    end
    if ::AppConfig.activate_users
      @subject    += "#{_('Please activate your %{name} account') % {:name => ::AppConfig.application_name}}"
      @body[:url]  = "#{::AppConfig.host}/activate/#{user.activation_code}"
    else
      @subject    += "#{_('Thank you for signing up for %{name}!') % {:name => ::AppConfig.application_name}}"
      @body[:url]  = "#{::AppConfig.host}/login/"
    end
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += "#{_('Your %{name} account has been activated!') % {:name => ::AppConfig.application_name}}"
    @body[:url]  = "#{::AppConfig.host}/login/"
  end

  def change_password(user, key)
    setup_email(user)
    @subject    += "#{_('Your requested password reset for %{name}') % {:name => ::AppConfig.application_name}}"
    @body[:url]  = "#{::AppConfig.secure_host}/change_password/#{key}"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "#{::AppConfig.mail.from}"
      headers      "Reply-to" => ::AppConfig.mail.from
      @subject     = ""
      @sent_on     = Time.now.utc
      @body[:user] = user
      content_type 'text/html'
    end
end

