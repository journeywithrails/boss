class Feedback < ActiveRecord::Base

  before_create :populate_fields
  def validate
    unless self.user_email.blank?
      unless self.user_email.match /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/i
        self.user_email = ""
      end
    end
    if self.text_to_send.blank?
      errors.add("Your message")
    end
  end
  
  def populate_fields
    self.response_status = "Open"
    if self.user_email.nil?
      self.user_email = ""
    end
  end
end
