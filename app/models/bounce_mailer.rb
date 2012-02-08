class BounceMailer < ActionMailer::Base
  helper LocalizationHelper
  def forward_bounce(email, bounce)
    recipients    email
    from          "#{::AppConfig.mail.from}"
    subject       _("Bounced Mail")
    body[:bounce] = bounce.body
    body[:sent_to] = bounce.delivery.recipients
    if (bounce.delivery.deliverable_type == 'Invoice')
      invoice = Invoice.find(bounce.delivery.deliverable_id)
      if (!invoice.nil?)
        body[:invoice_num] = invoice.unique_number
      end
    else
      body[:invoice_num] = ""
    end
    content_type "text/html"
  end
end

