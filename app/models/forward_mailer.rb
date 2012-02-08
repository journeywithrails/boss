class ForwardMailer < ActionMailer::Base
  
  def forward_reply(invoice, sender, content)
    recipients  invoice.created_by.email
    from        sender
    subject     "Re: Invoice #{invoice.unique_name}"
    body        content
  end
  
end

