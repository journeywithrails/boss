class SimplyAccountingInvoice < Invoice
  has_one_with_attributes :invoice_file

  belongs_to :superceded_by, :class_name => 'Invoice', :foreign_key => :superceded_by_id
  
  validates_length_of :simply_guid, :is => 32, :allow_nil => false

  validates_numericality_of :simply_amount_owing, :greater_than => 0, :less_than => BigDecimal('1000000')

  before_save :calculate_cached_amount

  include SimplyModelIntegration
  
  def validate
    # TODO: do we need to do validation on simply invoice, or do we trust it?
    # if (self.subtotal_amount - self.discount_amount + self.tax_1_amount + self.tax_2_amount) != self.total_amount
    #   errors.add('total_amount', 'does not add up')
    # end
  end

  def calculate_cached_amount
      self.paid_amount = self.paid
      self.owing_amount = self.amount_owing
  end

  def complete_profile
  end
  
  def must_have_exactly_one_unique_thingy
  end
    
  def calculate_discounted_total
    @tax_amount = BigDecimal.new('0')
    unless tax_1.nil?
      self.write_attribute('tax_1_amount', self.tax_1.amount)
      @tax_amount += self.tax_1.amount
    end
    unless tax_2.nil?
      self.write_attribute('tax_2_amount', self.tax_2.amount) unless tax_2.nil?
      @tax_amount += self.tax_2.amount
    end
  end
  
  def taxes=(values)
    if values.is_a?(Array) and values.all? { |v| v.is_a?(Hash) }
      build_taxes_with_attributes(values, true)
      taxes.each do |t|
        t.save!
      end
    else
      super
    end
  end
  
  def update_customer_contacts
  end

  def get_unique_number
  end

  def prepare_default_fields
  end
  
  def unique
    self.unique_name.to_s
  end
  
  def unique=(value)
    self.unique_name=(value)
  end
  
  def self.find_by_unique(u)
    find(:first, :conditions => ['unique_name = ? and superceded_by_id is null', u])
  end
  
  def amount_owing
    self.simply_amount_owing - paid
  end
  
  def line_items_total
    self.subtotal_amount
  end
  
  #RADAR has minor concurrency flaw
  # gets/creates access key for this invoice unless it has been superceded,
  # in which case it finds the uppermost superceding invoice and gets/creates
  # an access key for it
  def get_or_create_access_key_for_latest_invoice
    return nil unless created_by
    invoice = self unless self.superceded_by
    invoice ||= self.created_by.invoices.find(:all, :conditions => "simply_guid = ? and superceded_by_id is null")
    raise ::Sage::BusinessLogic::Exception::IncorrectDataException, 
            "invoice #{self.id} had multiple superceding invoices" if invoice.length > 1
    raise ::Sage::BusinessLogic::Exception::IncorrectDataException, 
            "invoice #{self.id} had no unsuperceded invoice" if invoice.length < 1
    invoice = invoice.first
    invoice.get_or_create_access_key
  end
    
  def get_superceding_key
    key = AccessKey.find(:first, :conditions => {:keyable_id => self.superceded_by_id})
    key
  end
  
  
  # FIXME probably not currently concurrency safe. I made a primitive, untested attempt to make it more 
  # concurrency safe, but I doubt it catches all cases -- mj
  def supercede_other_invoices
    return if self.created_by.nil?
    begin
      # assumes if another invoice supercedes before us, it will supercede 1 or more (should actually only
      # ever be one) invoices we are trying to supercede, and will also supercede us. So if we are
      # unable to supercede an invoice, everything is still ok so long as we + all the invoices
      # we were interested in superceded are now superceded
      # RADAR relies on supercede event working on any state of invoice!
      Invoice.transaction do
        existing_invoices = self.created_by.invoices.find(:all, :conditions => ["simply_guid = ? and status != 'superceded' and superceded_by_id is NULL and id < ?", self.simply_guid, self.id ])
        existing_invoices.each do |existing_invoice|
          existing_invoice.superceded_by = self
          raise Sage::BusinessLogic::Exception::ConcurrencyException unless existing_invoice.supercede!
        end
      end
    rescue Sage::BusinessLogic::Exception::ConcurrencyException => e
      consistent = true
      existing_invoices << self
      existing_invoices.each do |existing_invoice|
        existing_invoice.reload        
        consistent &&= self.superceded?
      end
      raise unless consistent
    end
  end
  
  def created_by_with_use_existing_taxes=(user)
    self.created_by_without_use_existing_taxes = user #RADAR another place where self is NECESSARY
    self.adjust_tax_keys_to_match_profile
  end
  alias_method_chain :created_by=, :use_existing_taxes

  def adjust_tax_keys_to_match_profile
    Tax::TaxesVersionOne.tax_keys.each do |key|
      puts "adjusting tax #{key}" if $log_on
      if (user_tax = self.created_by.profile.tax_for_key(key))
        tax_with_same_key = self.tax_for_key(key)
        tax_with_same_name = self.taxes.detect{|tax| tax.name_roughly == user_tax.name_roughly}
        puts "tax_with_same_name: #{tax_with_same_name.inspect}" if $log_on
        unless tax_with_same_name.nil? || tax_with_same_key.nil? || (tax_with_same_name == tax_with_same_key)
          tax_with_same_key.profile_key, tax_with_same_name.profile_key = tax_with_same_name.profile_key, tax_with_same_key.profile_key
          tax_with_same_key.save!
          tax_with_same_name.save!
        end
      end
    end
  end
  
  def mark_paid!
    payment = Payment.new(
      :created_by => self.created_by,
      :customer => self.customer,
      :amount => self.amount_owing,
      :pay_type => 'simply'
    )
    payment.save_and_apply(self)
  end
  
  def strict_validation?
    false
  end

  def supercedable?
    !self.superceded_by.nil?
  end
  
  def cached_pdf
    return false if invoice_file.nil?
    return false if invoice_file.db_file.nil?
    return invoice_file.db_file.data
  end
  
  def assert_payable_by(payment)
    if self.status == "draft" && payment.pay_type != 'simply'
      payment.errors.add_to_base("Cannot record a payment on a draft invoice")
      raise StandardError, "Cannot record a payment on a draft invoice"
    end
  end

  def should_setup_taxes
    false
  end
  
  #this is like sendable except it does not require us to know the created_by yet
  def processable?
    puts "checking processable? for invoice attributes #{(self.class.column_names - ["created_by_id", "customer_id", 'unique_name', 'unique_number', 'customer']).inspect}" if $log_on
    processable = self.valid_for_attributes?(self.class.column_names - ["created_by_id", "customer_id", 'unique_name', 'unique_number', 'customer'])
    self.customer.errors.clear # only way to NOT get the created_by error on customer because invoice validates_associated customer and valid_for_attributes doesn't prevent this
    processable
  end
  
  def delivering(delivery)
    supercede_other_invoices
    super
  end
  
end
