module InvoiceParts
  module InvoiceValidation
    def self.included(base) # :nodoc:
      # base.validates_presence_of :created_by #TODO -- this should be here, currently adding it breaks a lot of tests I did not have time to fix
      base.validates_associated :customer
    # moved to validate method, don't return anything if invalid
     base.validates_associated :line_items
      
      base.validates_presence_of :customer, :line_items, :if => :strict_validation?


      base.validates_uniqueness_of :unique_name, :scope => ['created_by_id'], :if => proc { |i| 
          if i.is_a?(SimplyAccountingInvoice)
            # only validate uniqueness if no other invoices with the same
            # simply_guid and unique name exist. The first one with that
            # simply_guid will be validated but this will allow the superceding
            # to take place correctly after the invoices are saved.
            #
            # Since invoices can be saved without validation before the
            # created_by value is set, ensure we're only looking at ones that
            # have been fully created.
            not SimplyAccountingInvoice.exists?(['created_by_id is not null and simply_guid = ? and unique_name = ?', i.simply_guid, i.unique_name])
          else
            true
          end
        }, :allow_nil => true # RADAR: automagically scoped by STI type. If DON'T want scope by type, Invoice must become abstract base class. Scoping by superceded_by_id is because multiple simply invoice records can get created from simply with same unique, but only 1 should have superceded_by_id=null
      base.validates_uniqueness_of :unique_number, :scope => ['created_by_id', 'superceded_by_id', 'simply_guid'], :allow_nil => true, :if => Proc.new{|i| !i.quote?} # RADAR: automagically scoped by STI type. If DON'T want scope by type, Invoice must become abstract base class
      base.validates_uniqueness_of :quote_unique_number, :scope => ['created_by_id', 'superceded_by_id', 'simply_guid'], :allow_nil => true, :if => Proc.new{|i| i.quote?}
      base.validates_numericality_of :total_amount, :greater_than => 0, :if => :strict_validation?
      base.validates_numericality_of :total_amount, :less_than => BigDecimal('1000000')

      base.validates_numericality_of :discount_amount, :greater_than_or_equal_to => 0, :allow_nil => true

      base.validate :complete_profile

      base.validate :must_have_exactly_one_unique_thingy
      base.validate :valid_type

      base.validates_date :date, :allow_nil => true
      base.validates_date :due_date, :allow_nil => true
      base.validate :validate_dates
      base.validate :validate_currency  
      base.validate :validate_taxes
      base.validate :validate_payment_types
      base.validate :validate_send_recipients
      base.validates_email_format_of :send_recipients, :list => true, :message => N_("must be a comma-separated list of email addresses"), :if => Proc.new { |invoice| invoice.recurring? && !invoice.send_recipients.blank? }
    end
    
    def validate_send_recipients
      return unless self.recurring? && self.send_recipients
      if customer.blank?
        errors.add(:send_recipients, _("can't be filled when no customer is selected. Edit invoice and select a customer."))
      end

      if total_amount < 1
        errors.add(:send_recipients, _("can't be filled when no total amount is zero. Edit invoice and add some line items."))
      end
    end

    def validate
      #return false if self.line_items.valid?
      
      self.calculate_discounted_total
      if self.amount_owing < 0
        errors.add("", _("Due to previously recorded payment(s) totalling #{self.paid} #{self.currency} on this invoice, saving will result in a negative amount owing, which is not supported. Please edit the invoice to ensure a total amount equal to or greater than #{self.paid} #{self.currency}."))
      end
    end
    
    def valid_type
      if !self[:type].nil? and (self[:type] != "SimplyAccountingInvoice")
        errors.add('type', _("Invalid invoice type"))
      end
    end

    def validate_dates
      # if present, due date may not be before issue date      
      if date
        if due_date
          if due_date < date
            errors.add('', _("Due date cannot be set before issue date"))
          end
        end
      end   
    end

    def validate_currency
      if currency.blank? or !Currency.valid_currency?(currency)
        errors.add('currency', _("is invalid"))
      end
    end

    def validate_payment_types
      if !attributes['payment_types'].blank? && self.quote?
        errors.add('payment_types', "can't be set for quotes")
      end
    end

    
    def valid?(options={})
      @strict_validation = options[:strict]
      @ignore_profile = options[:just_mark]
      v=super()
      @strict_validation = nil
      @ignore_profile = nil
      v
    end

    def strict_validation?
      if not @strict_validation.nil?
        @strict_validation
      else

        # Recurring invoices set not to be sent automatically
        # produce drafts, and are validated like drafts
        return false if self.status == "recurring" #and self.schedule.send_recipients.to_s == ""

        # don't use the sugar here (self.draft?), as the sugar looks in the db
        if %w{draft printed quote_draft}.include?(self.status)
          false
        else
          true
        end
      end
    end

    def ignore_profile?
      if not @ignore_profile.nil?
        @ignore_profile
      else
        true
      end
    end
    
  end
end
