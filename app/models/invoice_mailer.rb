# delivery.associate_with_access_key!(invoice_access_key)
class InvoiceMailer < ActionMailer::Base
  helper LocalizationHelper
  helper InvoicesHelper

  include ActionController::UrlWriter

  def send(delivery, controller, sent_at = Time.now)
    content_type 'text/html'
    invoice_mail(delivery, sent_at)
    setup_multipart_mail('send')
    # use controller instance to generate pdf on the fly
    if delivery.mail_options[:attach_pdf] || delivery.mail_options["attach_pdf"]
      pdf_attachment @invoice.pdf_name, controller.render_invoice_pdf(@invoice)
    end
  end

  def simply_send(delivery, controller, sent_at = Time.now)
    content_type 'text/html'
    invoice_mail(delivery, sent_at)
    setup_multipart_mail('simply_send')
    pdf_attachment(@invoice.pdf_name, @invoice.invoice_file.db_file.data_as_string)
  end

  # def remind(delivery, sent_at = Time.now)
  #   invoice_mail(delivery, controller, sent_at = Time.now)
  #   @subject    = 'InvoiceMailer#remind'
  # end
  # 
  # def thankyou(delivery, controller, sent_at = Time.now)
  #   invoice_mail(delivery, sent_at)
  #   @subject    = 'InvoiceMailer#thankyou'
  # end
  # 

  private

  def pdf_attachment(name, file)
    attachment_options = {
      :content_type => "application/pdf",
      :filename => name.sub(/(\.pdf|)$/, '.pdf')
    }
    attachment attachment_options do |a|        
      a.body = file
    end
  end

  def invoice_mail(delivery, sent_at = Time.now)
    @body       = {:message => delivery.body, :invoice => delivery.deliverable, :mail_options => delivery.mail_options, :company_name => delivery.company_name, :company_logo_url => delivery.company_logo_url}
    @recipients = delivery.recipients
    @from       = ::AppConfig.mail.from
    headers     "Reply-to" => delivery.reply_to
    headers["X-Delivery-ID"] = delivery.id
    @sent_on    = sent_at.utc
    @invoice = delivery.deliverable
    @subject = delivery.subject
    @subject ||= @invoice.default_delivery_subject
    @subject = "[copy] " + @subject if delivery.email_copy
    @body[:invoice_url] = @invoice.delivery_link_text(delivery)
  end
  
  def setup_multipart_mail(mail_name)
    part :content_type => "multipart/alternative" do |p|
      p.part  :content_type => 'text/plain',
      :transfer_encoding => 'quoted-printable',
              :body => render_message("#{mail_name}.text.plain.erb", @body)

      p.part  :content_type => 'text/html',
                :transfer_encoding => 'quoted-printable',
                :body => render_message("#{mail_name}.text.html.erb", @body)

    end
  end
end
