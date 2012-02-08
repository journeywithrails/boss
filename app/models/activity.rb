class Activity < ActiveRecord::Base
  belongs_to :invoice
  
  class << self
    def log_forward!(invoice, user)
      create(:invoice_id => invoice.id, :user_id => user.id, :body => "forward")
    end
    
    def log_send!(delivery, user)
      if delivery.deliverable_type == "Invoice"
        create(:invoice_id => delivery.deliverable_id, :user_id => user.id, :body => "sent", :extra => delivery.recipients)
      end
    end
  
    def log_update!(invoice, user)
      create(:invoice_id => invoice.id, :user_id => user.id, :body => "updated")
    end
  
    def log_create!(invoice, user)
      create(:invoice_id => invoice.id, :body => "created")
    end

    def log_bounce!(delivery, bounce_id)
      if delivery.deliverable_type == "Invoice"
        create(:invoice_id => delivery.deliverable_id, :body => "bounced")
      end
    end
  
    def log_view!(invoice_id, remote_ip)
      create(:invoice_id => invoice_id, :body => "viewed", :extra => remote_ip)
    end
    
    # payments todo: dry
    def log_payment!(invoice, payment)
      create(:invoice_id => invoice.id, :body => "payment_applied", :extra => "(#{payment.pay_type}, #{payment.amount} #{invoice.currency})")
    end
    
    def log_edit_payment!(invoice, payment)
      create(:invoice_id => invoice.id, :body => "payment_edited", :extra => "(#{payment.pay_type}, #{payment.amount} #{invoice.currency})")
    end
    
    def log_delete_payment!(invoice, payment)
      create(:invoice_id => invoice.id, :body => "payment_deleted", :extra => "(#{payment.pay_type}, #{payment.amount} #{invoice.currency})")
    end
    
  end
end
