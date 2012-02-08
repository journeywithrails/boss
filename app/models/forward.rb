class Forward# < ActiveRecord::Base
  
  def self.create_for(email)
    return unless email.match(/Delivered-To: info@billingboss.com/) and sender = locate_sender(email)
    
    invoice = locate_invoice_by_guid(email)
    forward_to_sender(invoice, sender, email) unless invoice.blank?
  end
  
  def self.forward_to_sender(invoice, sender, email)
    Activity.log_forward!(invoice, invoice.created_by)    
    ForwardMailer.deliver_forward_reply(invoice, sender, email)
  end
  
  protected
  def self.locate_sender(email)
    email.match(/^From:.*<(.*?)>/)[1]
  end
  
  def self.locate_invoice_by_guid(email)
    if guid = extract_access_key(email)
      ak = AccessKey.find_by_key(guid)
      ak.nil? ? false : Invoice.find(ak.keyable_id)
    end
  end
  
  def self.extract_access_key(email)
    # todo : fix this
    if k = email.match(/access\/\w*/)
      k[0].gsub('access/',"")
    end
  end
  
  
end
