class BookkeepingInvitationMailer < ActionMailer::Base
  helper LocalizationHelper

  def send_invitation(delivery, controller, sent_at = Time.now)
    content_type 'text/html'
    invitation_mail(delivery, sent_at)
    @subject    = delivery.subject
    bookkeeping_invitation = delivery.deliverable
    # @body       = {}
    @body.merge!(:bookkeeper_invitation_url => bookkeeper_invitation_url(bookkeeping_invitation.get_or_create_access_key))
    # @recipients = ''
    #@sent_on    = sent_at
  end

  
  def self.options_for_send_invitation(delivery)
    options = {}
    invitation = delivery.deliverable
    options[:show_recipients] = invitation.invitee.nil?
    options[:name] = invitation.invitor.name

    if !invitation.invitee.nil?
      delivery.recipients = invitation.invitee.email
    end
    delivery.subject = _("%{name} would like to share their invoice data.") % {:name => options[:name]} 
    delivery.body = _("%{name} is using Billing Boss, a free online tool to create, track and manage their invoices and would like to share their data with you.\n\nWith Billing Boss you will get a bookkeeper or accountant's view of %{name}'s invoice activities and won't need to worry about sending files back and forth or sorting through a mountain of paper work.") % {:name => options[:name]}

    options
  end
  
  private
  def invitation_mail(delivery, sent_at = Time.now)
    @body       = {:message => delivery.body, :invitation => delivery.deliverable, :mail_options => delivery.mail_options}
    @recipients = delivery.recipients
    @from       = ::AppConfig.mail.from
    headers     "Reply-to" => delivery.deliverable.invitor.email
    @sent_on    = sent_at
  end
  
  
  #FIXME could not get url methods to work in mails, & gave up trying. When have a chance, revisit
  def bookkeeper_invitation_url(access)
    "#{::AppConfig.mail.host}/access/#{access}"
  end
  
  
  
end
