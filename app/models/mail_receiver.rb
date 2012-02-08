class MailReceiver < ActionMailer::Base 

  def receive(email)
    email_string = email.to_s
    
    if email_string.match(/MAILER-DAEMON/i)
      Bounce.create_for(email_string)
    else
      Forward.create_for(email_string)
    end
  end
  
end
