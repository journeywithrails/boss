module InvoiceParts
  module InvoiceStates
    def self.included(base) # :nodoc:

      #RADAR: the first event called on a new record will fire the transition but won't save the state. 
      # Behind the scenes, the record will have been written to the database! The fix is to
      # only fire events on records that have already been saved to the database.
      base.acts_as_state_machine :initial => :draft, :column => 'status' 
      base.state :draft, :enter => :setup_taxes
      base.state :quote_draft
      base.state :quote_sent
      base.state :printed
      base.state :sent
      base.state :changed  
      base.state :resent
      base.state :paid
      base.state :acknowledged
      base.state :superceded
      base.state :recurring
      
      base.event :save_draft do  
        transitions :from => :draft, :to => :draft  
        transitions :from => :printed, :to => :draft  
        transitions :from => :sent, :to => :changed
        transitions :from => :quote_draft, :to => :draft
        transitions :from => :quote_sent, :to => :draft
      end

      base.event :save_quote do
        transitions :from => :draft, :to => :quote_draft
      end

      base.event :save_recurring do
        transitions :from => :draft, :to => :recurring
      end

      base.event :supercede do  
        transitions :from => :draft, :to => :superceded, :guard => :supercedable?
        transitions :from => :changed, :to => :superceded, :guard => :supercedable?
        transitions :from => :printed, :to => :superceded, :guard => :supercedable?
        transitions :from => :acknowledged, :to => :superceded, :guard => :supercedable?
        transitions :from => :sent, :to => :superceded, :guard => :supercedable?
        transitions :from => :resent, :to => :superceded, :guard => :supercedable?
        transitions :from => :superceded, :to => :superceded, :guard => :supercedable?
      end

      base.event :deliver do  
        transitions :from => :draft, :to => :sent, :guard => :sendable?
        transitions :from => :printed, :to => :sent, :guard => :sendable?
        transitions :from => :sent, :to => :sent, :guard => :sendable?
        transitions :from => :resent, :to => :resent, :guard => :sendable?
        transitions :from => :changed, :to => :resent, :guard => :sendable?
        transitions :from => :acknowledged, :to => :acknowledged, :guard => :sendable?
        transitions :from => :paid, :to => :paid, :guard => :sendable?
        transitions :from => :quote_draft, :to => :quote_sent, :guard => :sendable?
        transitions :from => :quote_sent, :to => :quote_sent, :guard => :sendable?
      end

      base.event :mark_sent do
        transitions :from => :printed, :to => :sent, :guard => :sendable?
        transitions :from => :draft, :to => :sent, :guard => :sendable?
      end
      
      base.event :mark_sent_without_sending do
        transitions :from => :printed, :to => :sent, :guard => :markable_as_sent?
        transitions :from => :draft, :to => :sent, :guard => :markable_as_sent?
      end      

      base.event :save_change do  
        transitions :from => :draft, :to => :draft
        transitions :from => :printed, :to => :draft
        transitions :from => :sent, :to => :changed  
        transitions :from => :resent, :to => :changed  
        transitions :from => :changed, :to => :changed  
        transitions :from => :paid, :to => :acknowledged  
      end  

      base.event :print do
        transitions :from => :draft, :to => :printed  
        transitions :from => :changed, :to => :printed
      end

      base.event :pay do
        transitions :from => :draft, :to => :paid
        transitions :from => :changed, :to => :paid
        transitions :from => :printed, :to => :paid
        transitions :from => :acknowledged, :to => :paid
        transitions :from => :sent, :to => :paid
        transitions :from => :resent, :to => :paid
        transitions :from => :paid, :to => :paid
      end

      base.event :acknowledge do
        transitions :from => :draft, :to => :acknowledged
        transitions :from => :changed, :to => :acknowledged
        transitions :from => :printed, :to => :acknowledged
        transitions :from => :acknowledged, :to => :acknowledged
        transitions :from => :paid, :to => :acknowledged
        transitions :from => :sent, :to => :acknowledged
        transitions :from => :resent, :to => :acknowledged
      end
      
      base.event :cancel_payment do
        transitions :from => :paid, :to => :acknowledged
      end
    end
    
    def supercedable?
      false
    end
  end
end
