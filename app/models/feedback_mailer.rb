class FeedbackMailer < ActionMailer::Base

  helper LocalizationHelper
  def feedback(msg, from, user_name)
    @subject    = _('Feedback received from website')
    @body[:user_msg] = msg
    @body[:user_email] = from
    @body[:user_name] = user_name    
    @recipients = 'admin.billingboss@sage.com'
    @from       = ::AppConfig.mail.from
    headers     "Reply-to" => ::AppConfig.mail.from
    @sent_on    = Time.now
    @headers    = {}
  end
  
  def feedback_response(user_name, user_email, response_text, text_to_send)
    content_type 'text/html'
    @subject    = _('Reply to your feedback on Billing Boss')
    @body[:user_name] = user_name
    @body[:user_email] = user_email
    @body[:response_text] = response_text
    @body[:text_to_send] = text_to_send    
    @recipients = user_email #'richard@10.152.17.65'
    @from       = ::AppConfig.mail.from
    headers     "Reply-to" => ::AppConfig.mail.from
    @sent_on    = Time.now
    @headers    = {}
  end
end
