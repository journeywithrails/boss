class Invoice < ActiveRecord::Base

  include Sage::BusinessLogic::Exception

  acts_as_paranoid # when records are deleted they aren't really deleted, but marked as deleted
  AmountDiscountType = 'amount'
  PercentDiscountType = 'percent'

  include Princely::Storage::CacheableEntity
  after_update :pdf_dirty_cache, :update_payments
  after_save :update_user_currency
  DiscountTypes = [PercentDiscountType, AmountDiscountType]
  
  has_many_with_attributes :line_items, 
      {:not_found_exception => Sage::ActiveRecord::Exception::OutOfScope},
      {:dependent => :delete_all, :order => "position" }
  belongs_to_with_attributes :customer, {:push => :created_by_id}
  belongs_to_with_attributes :contact, {}, :conditions => "customer_id = contacts.customer_id"
  
  belongs_to :created_by, :class_name => 'User', :foreign_key => :created_by_id
  has_many :pay_applications, :dependent => :nullify
  has_many :payments, :through => :pay_applications, :dependent => :destroy
  has_many :taxes, :as => :taxable, :class_name => 'Tax', :dependent => :delete_all
  
  has_many :activities, :dependent => :destroy
  has_one :schedule, :dependent => :destroy
  has_many :deliveries, :as => :deliverable, :conditions => ['status = ? AND access_key_id != ? ', 'sent', 'nil']
  has_many :generated_invoices, :class_name => 'Invoice', :foreign_key => :recurring_invoice_id
  belongs_to :recurring_invoice, :class_name => 'Invoice'
  
  include ::Tax::TaxesVersionOne

  def created_by?(user)
    self.created_by == user
  end
  
  def self.currency_exists?(currency)
    find(:all, :conditions => {:deleted_at => nil}).map(&:currency).include?(currency)
  end
  
  def self.first_fallback
    find(:first, :conditions => {:deleted_at => nil})
  end

  def self.default_payment_types(user, currency)
    if invoice = user.invoices.find_last_by_currency(currency)
      invoice.selected_payment_types
    else
      user.payment_types(currency)
    end
  end

  def self.find_last_by_currency(currency)
    find(:first, :conditions => ['currency = ?', currency], :order => 'updated_at desc')
  end

  def self.find_all_without_quotes
     Invoice.find(:all).reject{|e| e.status =~ /^quote/}
  end
  
  # RADAR not sure why but I using create on associations (user.invoices.create) is not working properly -- 
  # the id of the invoice object doesn't get set
  # must be something to do with this overriding of Invoice.new. Will figure out when becomes
  # a blocker. 
   def self.new(attrs={})
     RAILS_DEFAULT_LOGGER.debug "new invoice: #{attrs.inspect}"     
     attrs[:type] = attrs.delete(:invoice_type) if !attrs[:invoice_type].nil?    
     if self == Invoice
       if attrs && !attrs[:type].nil?
         klass = attrs.delete(:type).constantize
         raise StandardError, "#{klass.name} is not a type of Invoice" unless klass < Invoice
         klass.new(attrs)
       else
         return super
       end
     else
       return super
     end
   end
  
  # after saving, if we created a new contact for existing customer via virtual attribute, add it to customer's contacts
  before_save {|invoice| (invoice.contact ||= invoice.customer.default_contact) unless invoice.customer.nil?}
  #before save, recalculate invoice total with discount, etc
  before_save :calculate_discounted_total
  after_save :save_taxes
  after_save :update_customer_contacts
  before_create :before_create_assign_default_payment_types
  before_validation :get_unique_number, :set_default_currency, :clean_up_taxes
  before_save :get_unique_number
  acts_as_keyed
  acts_as_configurable
  

  include InvoiceParts::InvoiceStates
  include InvoiceParts::InvoiceValidation
  extend InvoiceParts::InvoiceFilters

  def self.build_from_parent_and_params(parent, params, is_quote=false)
    initial_params = {}
    initial_params[:type] = params.delete(:invoice_type) if params.has_key?(:invoice_type)
    invoice = parent.invoices.build(initial_params)

    invoice.status = 'quote_draft' if is_quote
    invoice.prepare_default_fields
    invoice.setup_taxes
    invoice.attributes = params
    invoice
  end
  
  def prepare_default_fields
    self.unique = self.generate_next_auto_number
    #doing this at the controller level because the need for timezone information
    #self.date = Date.today 
  end
  
  #TODO -- it would be better if we figured out why we have blank-named taxes in the first place
  def clean_up_taxes
    deletable_taxes = self.taxes.find_all{|t| t.name.blank?}
    deletable_taxes.each do|t|
      t.destroy
      self.taxes.delete(t)
    end
  end
  
  def set_default_currency
    if self.currency.blank? or !Currency.valid_currency?(self.currency)
      if !self.created_by.blank? and !profile.blank?
        if !profile.currency.blank? and Currency.valid_currency?(profile.currency)
          self.currency = profile.currency
        else
          self.currency = Currency.default_currency
        end
      end
    end
  end
    
  def update_customer_contacts
    unless self.contact.nil?
      if self.customer.nil?
        raise Sage::BusinessLogic::Exception::OrphanedContactException.new("contact was added to invoice (#{self.id}) with no customer")
      end
      
      if self.contact.customer.nil?
        self.contact.update_attribute(:customer_id, self.customer_id)
      elsif self.contact.customer != self.customer
        self.contact = nil
        self.save(false)
        
      end
    end
  end

  def customer_name
    customer.nil? ? nil : self.customer.name
  end
  
  def update_user_currency
    if !self.created_by.blank? and !profile.blank?
      profile.update_attribute(:currency, self.currency)
    end
  end
  
  ###stuff related to unique numbers
  #at least one of the two must always be nil

    #max length is 128. we add payment id in form -00000001
  def unique_for_paypal
     u = self.unique.to_s
    return '' if u.nil?
    u = u.to_s
    if u.length > 118
      u[0..(119-self.id.to_s.length)] + self.id.to_s
    else
      u
    end
  end

  def must_have_exactly_one_unique_thingy
    if self.quote?
      if quote_unique_number.nil? and unique_name.blank?
        # raise Sage::ActiveRecord::Exception::ConditionsViolatedException.new("Missing unique value (this isn't supposed to happen, check code")
        errors.add('quote_unique_number', 'Either quote_unique_number or unique_name must be set to a unique value')
      end
      if !quote_unique_number.nil? and !unique_name.blank?
        # raise Sage::ActiveRecord::Exception::ConditionsViolatedException.new("Have both unique name and number (this isn't supposed to happen, check code")
        errors.add('quote_unique_number', 'Only one of quote_unique_number or unique_name can be set')
      end
      if !unique_number.nil?
        errors.add('quote_unique_number', 'Quotes can\t have unique_numbers (should be quote_unique_number)' )
      end
    else
      if unique_number.nil? and unique_name.blank? and !recurring?
        # raise Sage::ActiveRecord::Exception::ConditionsViolatedException.new("Missing unique value (this isn't supposed to happen, check code")
        errors.add('unique_number', 'Either unique_number or unique_name must be set to a unique value')
      end
      if !unique_number.nil? and !unique_name.blank?
        # raise Sage::ActiveRecord::Exception::ConditionsViolatedException.new("Have both unique name and number (this isn't supposed to happen, check code")
        errors.add('unique_number', 'Only one of unique_number or unique_name can be set')
      end
    end
    
  end
  
  def unique
    if (self.quote? ? self.quote_unique_number : self.unique_number).nil?
      self.unique_name.to_s
    elsif self.unique_name.blank?
      self.quote? ?  self.quote_unique_number.to_s : self.unique_number.to_s      
    end
  end

  def unique=(value)    
    if value.to_s.index(/\A0/) or value.to_s.index(/\A\d+\Z/).nil?  #nothing but digits   
      assign_this_to_unique_name(value)
    else
	    if value.is_a?(Bignum)
	     	assign_this_to_unique_name(value)
	    elsif value.to_i >= 1000000000
	    	 assign_this_to_unique_name(value)
	    else
		 self.unique_name = nil
		 if self.quote?
		 self.quote_unique_number = value.to_i
		else
		 self.unique_number = value.to_i
		end
	    end
    end      
    value
  end

   def assign_this_to_unique_name(value)
	self.unique_name = value
	if self.quote?
	self.quote_unique_number = nil
	else
	self.unique_number = nil
	end
   end

  
  def wanted_auto
    @wanted_auto
  end
  
  def available_auto
    @available_auto
  end
  
  def wanted_auto=(value)
    @wanted_auto=value
  end
  
  def available_auto=(value)
    @available_auto=value
  end
  
  def get_unique_number
    return if self.recurring?

#    puts "get unique number on: " + self.inspect
    self.unique_number = nil if self.quote?

    return if self.created_by.nil?
    if self.unique_name.blank? and ( (self.quote? ? self.quote_unique_number : self.unique_number).nil?)
      self.unique_name = nil
      self.unique = self.generate_next_auto_number
    end
  end

  def quote_or_invoice_unique_number
     self.quote? ? self.quote_unique_number : self.unique_number
  end

  def unique_number_field_name
    self.quote? ? "quote_unique_number" : "unique_number"
  end

  def generate_next_auto_number(start_number="none")
    if self.quote?
      self.created_by.generate_next_auto_number start_number, 'quote_unique_number', "quote_unique_number IS NOT NULL"
    else
      self.created_by.generate_next_auto_number start_number
    end
  end

  def unique_available?
      confirmation_number = self.generate_next_auto_number( self.unique )
      if (confirmation_number == self.unique)
        return true
      else
        return confirmation_number
      end
  end
  
  def unique_auto?    
    if self.quote_or_invoice_unique_number.nil? or self.quote_or_invoice_unique_number < 1
      return false
    else 
      return true
    end
  end
  ###end unique number stuff

  # ensure any assigned invoice contact is one of invoice.customer's contacts
  alias_method :old_contact=, :contact=
  def contact=(c)
    unless c.nil? or c.new_record?
      raise Sage::ActiveRecord::Exception::ConditionsViolatedException.new("for invoice (#{self.id}) customer (#{self.customer_id}) does not match customer of invoice.contact (#{c.customer_id})") unless c.customer_id == self.customer_id 
    end
    self.old_contact = c 
  end
  
  def prune_empty_ending_line_items(reload=false)
    self.line_items.reverse_each {|li| 
      if li.unit.blank? and 
         li.description.blank? and 
         li.quantity.blank? and 
         li.price.blank?  
        li.destroy 
      else
         break
       end
    }
    self.line_items(true) if reload
  end
  
  def line_items_total_for_tax(profile_key)    
    line_items.reject(){|li| li.should_destroy?}
    line_item_total = BigDecimal.new("0").round(2)
    line_items.each do |li|
      if li.taxable_for?(profile_key)
        line_item_total += li.subtotal
      end
    end
    return line_item_total
  end
  
  def line_items_total
    
    line_items.reject(){|li| li.should_destroy?}.
      inject(BigDecimal.new("0")){|sum, li| sum + li.subtotal}.round(2)

  end 
  def calculate_discounted_total

    ic = InvoiceCalculator.setup_for(self)
    self.discount_amount = ic.discount 
    @tax_amount = ic.tax # RADAR: side effect, caches the individual tax_amount on individual taxes

    # cache tax amounts on invoice. #RADAR: kluge to avoid nasty query for summary row 
    self.write_attribute('tax_1_amount', self.tax_1.amount) unless tax_1.nil?
    self.write_attribute('tax_2_amount', self.tax_2.amount) unless tax_2.nil?
    
    self.total_amount = ic.total
    self.subtotal_amount = self.line_items_total
    self.paid_amount = self.paid
    self.owing_amount = self.amount_owing
  end
  
  def gst
    tax = taxes.detect { |tax| tax.name =~ /\A(gst|hst)\Z/i }
    tax.amount.to_f if tax and tax.amount
  end

  def pst
    tax = taxes.detect { |tax| tax.name !~ /\A(gst|hst)\Z/i }
    tax.amount.to_f if tax and tax.amount
  end

  def tax1
    tax = taxes.first
    tax.amount.to_f if tax and tax.amount
  end

  def tax2
    tax = taxes[1]
    tax.amount.to_f if tax and tax.amount
  end

  def total_taxes
    taxes.inject(BigDecimal.new('0.0')) do |total, tax|
      if tax.amount
        total + tax.amount
      else
        total
      end
    end.to_f
  end

  def tax_amount
    calculate_discounted_total if @tax_amount.nil?
    @tax_amount
  end
  
  def tax_1_amount
    calculate_discounted_total if @tax_amount.nil?
    tax = tax_1
    tax.nil? ? BigDecimal("0.0") : tax.amount
  end

  def tax_2_amount
    calculate_discounted_total if @tax_amount.nil?
    tax = tax_2
    tax.nil? ? BigDecimal("0.0") : tax.amount
  end

  def total_as_cents #FIXME -- support other currencies
    self.total_amount.mult(BigDecimal.new('100'), 0)
  end
  
  def total_taxes_as_cents #FIXME -- support other currencies
    BigDecimal.new(self.total_taxes.to_s).mult(BigDecimal.new('100'), 0)
  end
  
  def sendable?(msgs={})    
    returning self.valid?({:strict => true, :just_mark => false}) do
      unless self.customer.nil?
        self.customer.valid?
      end
    end
  end
  
  def markable_as_sent?(msgs={})    
    return self.valid?({:strict => true, :just_mark => true})
  end
  
  def payment_recordable?(immediately=false)
    return false if self.meta_status == META_STATUS_QUOTE
    return false if self.meta_status == META_STATUS_PAID
    return false if self.meta_status == META_STATUS_DRAFT && (immediately || !self.markable_as_sent?)
    return false if self.customer.nil?
    return true
  end
  
  def has_line_items?
    line_items.count > 0
  end
  
  def self.find_by_unique(u)
    if u.respond_to?(:index) and u.index(/\A[+\-]?\d+\Z/).nil?
      find_by_unique_name(u)
    else
      find_by_unique_number(u)
    end
  end

  def assert_payable_by(payment)
    if self.quote?
      payment.errors.add_to_base(_("Cannot record a payment on a quote"))
      raise StandardError, _("Cannot record a payment on a quote")
    end

    if self.status == "draft"
      payment.errors.add_to_base(_("Cannot record a payment on a draft invoice"))
      raise StandardError, _("Cannot record a payment on a draft invoice")
    end
  end
  
  def paid
    self.pay_applications.inject(BigDecimal.new("0")) {|sum, p| sum + p.amount }
  end

  def profile
    created_by.profile
  end

  def amount_owing
    self.total_amount - paid
  end
  
  def total_amount
    if read_attribute('total_amount').nil?
      self.calculate_discounted_total
    end
    read_attribute('total_amount')
  end
  
  def fully_paid?
    self.amount_owing <= BigDecimal.new("0")
  end

  def acknowledge_payment(reload=false)
    self.reload if reload #RADAR
    self.calculate_discounted_total
    self.save(false)
    #internal assertion: invoice.amount_owing and invoice.paid? must agree.
    if self.paid? and self.amount_owing != 0
      self.update_attribute(:status, 'acknowledged')
      #raise BillingError, "error in Invoice#{}update_payment_state: invoice #{self.id} is status paid but amount owing is #{self.amount_owing}"
    end
    
    if self.fully_paid?
      unless self.pay!
        e = CantPerformEventException.new(self, :pay)
        if (self.paid?)
          raise e, _('Invoice has already been fully paid.')
        else
          raise e, e.message
        end
      end      
    else
      unless self.acknowledge!
        e =  CantPerformEventException.new(self, :acknowledge)
        raise e, e.message
      end      
    end
  end
  
  
  def description
    read_attribute(:description) || _("Invoice: %{num}") % { :num => self.unique }
  end
  
  #have no idea WhyTF the above method has the stuff after the ||,
  #but I don't feel like changing a gazillion tests
  #so the method below will return just the description or nothing
  def description_clean
    read_attribute(:description)
  end
  
  def description_for_paypal
    out = _("Invoice No: \#\#\# Invoice Date: %{date} Invoice Amount: %{amt} Amount Due: %{due}") % { :date => self.created_at.to_formatted_s(:DDMMYYYY), :amt => self.amount_owing, :due => self.amount_owing}
    chars = (131 - out.length)
    no = self.unique.to_s[0...chars]
    out.sub('###', no)
  end
  
  
  def discount_string
    #self.calculate_discounted_total requires huge amount of time/queries! instead depend on it being properly cached
    if self.discount_value.nil? or (self.discount_value == BigDecimal('0.0'))
      ''
    else
      case self.discount_type
      when AmountDiscountType
        self.currency_string(self.discount_value)
      when PercentDiscountType
        "#{self.discount_value}%"
      end
    end
  end

  # Taxes
  #---------
  # taxes are controlled by individual invoices. When an invoice is created, the taxes that are enabled in the customer are copied to the invoice. If the customer defines no taxes, the taxes enabled in the user profile are copied to the invoice. If the invoice is in a draft state and has enabled taxes whose values were never specifically set and whose values now differ from the values of the parent tax in the customer and/or user profile, the user is prompted when saving the invoice to update the tax to represent the current values.
  
  
  # look at the taxes on the current customer. If we have any taxes with profile_keys matching a tax in customer.taxes whose parent is not the customer tax, throw it away and use the customer tax. However, if the tax was edited, use the values in the original tax and mark it edited. Similarly for created_by. This is called whenever the invoice enters the draft state and whenever created_by= or customer= is called
  
  
  
  def setup_taxes
    if self.taxes.empty?
      # we have no taxes yet, so copy them all from user
      #RADAR: this assumes we always disable taxes to turn them off, not delete them
      unless self.created_by.nil?
        inherit_enabled = self.new_record?
        self.created_by.inherit_taxes(self, inherit_enabled)
      end
    else
      [self.created_by, self.customer].each do |tax_origin|
        unless tax_origin.nil?
          tax_origin.taxes.each do |parent_tax|
            # look for a tax with same profile_key as parent tax
            invoice_tax = self.tax_for_key(parent_tax.profile_key)
            if invoice_tax
              # if invoice already has this tax, check if its ancestry has changed
              unless invoice_tax.parent and (invoice_tax.parent.id == parent_tax.id)
                changed_attrs = invoice_tax.changed_attributes
                self.taxes.delete(invoice_tax)
                invoice_tax.destroy
                self.taxes << parent_tax.new_copy(changed_attrs)
              end
            else
              # if invoice does not have this tax, add it but set it to enabled = false
              self.taxes << parent_tax.new_copy(:enabled => false)
            end
          end
        end
      end
    end
  end
  
  def will_edit_taxes(params)
    puts "will_edit_taxes. current #{ }taxes: #{self.taxes.length}" if $log_on
    
    ::Tax::TaxesVersionOne.each_tax_key do |key|
      param_key = "#{key}_enabled"
      if params[param_key] && params[param_key] != "false" && params[param_key] != "0"
        puts "self.tax_for_key(#{key}): #{self.tax_for_key(key).inspect}" if $log_on
        if self.tax_for_key(key).nil?
           if self.customer
            puts "inherit #{key} from customer" if $log_on
            self.customer.inherit_tax(key, self, true)
            puts "now #{ }taxes: #{self.taxes.length}" if $log_on
          else
            puts "inherit #{key} from user" if $log_on
            self.created_by.inherit_tax(key, self, true)
            puts "now #{ }taxes: #{self.taxes.length}" if $log_on
          end
        end
      end
    end
  end
  
  def created_by_with_setup_taxes=(value)
    do_setup = should_setup_taxes && (self.created_by != value) && !value.nil?
    self.created_by_without_setup_taxes = value
    if do_setup
      self.setup_taxes
    end
  end
  alias_method_chain :created_by=, :setup_taxes

  def customer_with_setup_taxes=(value)
    do_setup = should_setup_taxes && (self.customer != value) && !created_by.nil?
    self.customer_without_setup_taxes = value
    setup_taxes if do_setup
  end
  alias_method_chain :customer=, :setup_taxes

  # returns all taxes if they are edited & enabled, or if they are not 


  def taxes_for_editing(ignore_status=true)
    tax_arr = []
    self.taxes.each do |tax|
      if %w{draft printed}.include?(self.status) or ignore_status   
      #RADAR: if you plan to re-add tax.enabled? clause to the line below, check with me first please
      #i removed it for a good reason -eugene
      # note from mj: if we have a chance, it might be better to fix the validation problems.
        tax_arr << tax if ((tax.edited) || (tax.root.enabled && !tax.edited))
      else
        tax_arr << tax if (tax.enabled || (tax.root.enabled && !tax.edited))
      end
    end
    return tax_arr.sort{|x, y| x.profile_key <=> y.profile_key}
  end
  
  def discount_before_tax
    if read_attribute('discount_before_tax').nil?
      if (!self.created_by.nil?) and (!profile.nil?)
        before_tax = profile.discount_before_tax
        self.discount_before_tax = before_tax
      end
    end
    read_attribute('discount_before_tax')
  end
  
  #TODO 
  def currency_string(amt)
    _("$%.2f") % amt.round(2)
  end

  def self.overview_listing_json_params
    { :only    => [:invoices, :id, :customer_id,:date,:total_amount,:status, :currency], 
      :methods => [:unique,:customer_name,:amount_owing,:invoice_type_for_css] }
  end
  
  def invoice_type_for_css
    self.class.name.underscore.dasherize
  end
  
  def default_recipients
    self.contact && self.contact.email
  end
  
  def default_delivery_subject
    puts "default_delivery_subject" if $log_on
    InvoicesHelper.i_(self, 'New invoice from %{sender}') %{ :sender => self.created_by.settings[:company_name]}
  end

  META_STATUS_NONE        = 0 # used for filtering
  META_STATUS_PAST_DUE    = 1
  META_STATUS_OUTSTANDING = 2
  META_STATUS_DRAFT       = 3
  META_STATUS_PAID        = 4
  META_STATUS_QUOTE       = 5
  META_STATUS_RECURRING   = 6

  def meta_status_string
    case meta_status
      when META_STATUS_PAST_DUE
        _('Past Due Invoice')
      when META_STATUS_OUTSTANDING
        _('Outstanding Invoice')
      when META_STATUS_DRAFT
        _('Draft Invoice')
      when META_STATUS_PAID
        _('Paid Invoice')
      when META_STATUS_QUOTE
        _('Quote')
      when META_STATUS_RECURRING
        _('Recurring Invoice')
    end
  end
  
  def brief_meta_status_string
    case meta_status
      when META_STATUS_PAST_DUE
        _('Past Due')
      when META_STATUS_OUTSTANDING
        _('Outstanding')
      when META_STATUS_DRAFT
        _('Draft')
      when META_STATUS_PAID
        _('Paid')
      when META_STATUS_QUOTE
        _('Quote')
      when META_STATUS_RECURRING
        _('Recurring')
    end
  end

  def meta_status
    case status
      when 'sent', 'resent', 'changed', 'acknowledged'
        if (not self.due_date.nil? and self.due_date <= Date.today )
          META_STATUS_PAST_DUE
         else
          META_STATUS_OUTSTANDING
        end
      when 'draft', 'printed'
        META_STATUS_DRAFT
      when 'paid'
        META_STATUS_PAID
       when 'quote_draft', 'quote_sent'
        META_STATUS_QUOTE
      when 'recurring'
        META_STATUS_RECURRING
    end
  end
  
  def quote?
    self.meta_status == META_STATUS_QUOTE
  end

  def recurring?
    self.status == 'recurring'
  end

  def convert_quote_to_invoice!
    self.save_draft!
    self.save!
#    self.update_attributes(:status => "")
  end

  def complete_profile
      if self.strict_validation? and !self.ignore_profile? and !self.created_by.profile.is_complete?
        errors.add('', _("Company address is not complete. You can complete your company address information in Settings."))
      end
  end

  def pdf_name
    # pdf_filename_max_length: 64
    name = _("Invoice")
    name + "_#{sanitize_filename(self.unique.to_s)}"[0...::AppConfig.invoice.pdf_filename_max_length - (4 + name.length)] # minus _.pdf plus name_length
  end
  
  def sanitize_filename(filename)
    returning filename.strip do |name|
      # NOTE: File.basename doesn't work right with Windows paths on Unix
      # get only the filename, not the whole path
      name.gsub!(/^.*(\\|\/)/, '')
      
      # Finally, replace all non alphanumeric, underscore or periods with underscore
      name.gsub!(/[^\w\.\-]/, '_')
    end
  end
  
  def save!
    super
  end
  
  def save_taxes
    self.taxes.each(&:save!) #FIXME: all tests still pass if I comment out this line!
  end

  def active_payment_with_access_key(access_key)
    self.class.uncached do
      payments.find_active_with_access_key(access_key)
    end
  end

  def cancelled_payment_with_gateway_token(gateway_token)
    self.class.uncached do
      payments.find_cancelled_with_gateway_token(gateway_token)
    end
  end

  def cancelled_no_redo_payment_with_gateway_token(gateway_token)
    self.class.uncached do
      payments.find_cancelled_no_redo_with_gateway_token(gateway_token)
    end
  end

  def gateway_recipient_name(gateway_name)
		if (user_gateway(gateway_name).nil?)
			''
    else
			g = user_gateway(gateway_name).gateway
			g.display_recipient_name
    end
  end

  def payment_gateway_credentials(gateway_name)
    ug = user_gateway(gateway_name)
    ug.params if ug
  end
  
  # FIXME: this method (along with all payment_url methods on gateways) is no longer in use
  def url_for_gateway(gateway_name)
    user_gateway(gateway_name).payment_url(self)
  end

  def user_gateway(gateway_name)
    created_by.user_gateway(gateway_name) if any_gateway_possible?
  end

  def payment_types=(array)
    if array and not array.empty?
      self['payment_types'] = array.uniq.compact.join(',')
    else
      self['payment_types'] = nil
    end
  end

  # Should usually use selected_payment_types which also filters for if a given
  # gateway has become invalid.  For example if payment_types includes paypal,
  # but the user unregisters their paypal account.
  def payment_types
    self['payment_types'].to_s.split(/,/).map { |x| x.to_sym }
  end

  def all_payment_types
    if any_gateway_possible?
      created_by.payment_types(currency)
    else
      []
    end
  end

  def selected_payment_types
    selected = payment_types
    all_payment_types.select { |pt| selected.include?(pt) }
  end

  def selected_payment_type?(payment_type)
    selected_payment_types.include?(payment_type)
  end

  def gateway_class(payment_type)
    if any_gateway_possible?
      created_by.gateway_class(currency, payment_type)
    end
  end

  def payment_choice?
    selected_payment_types.length > 1
  end

  def can_pay?
    selected_payment_types.length > 0
  end

  def before_create_assign_default_payment_types
    if any_gateway_possible?
      self.payment_types = Invoice.default_payment_types(created_by, currency)
    end
    true
  end

  # callback from the Delivery#deliver! method (visitor pattern style)
  def delivering(delivery)
    self.payment_types = [delivery.mail_options['payment_types']].flatten
  end

  def using_user_gateways
    created_by.user_gateways_for(currency, selected_payment_types).select do |ug|
      ug.handle_invoice?(self)
    end
  end

  def delivery_link_text(delivery)
    invoice_access_key = create_access_key

    delivery.associate_with_access_key(invoice_access_key)
    link = { :link => "#{::AppConfig.mail.secure_host}/access/#{invoice_access_key}" }
    if selected_payment_types.any?
      _('To view or pay this invoice online, please go to %{link}') %{:link =>  link}
    else
      InvoicesHelper.i_(self, 'To view this invoice online, please go to %{link}') %{:link =>  link}
    end
  end

  def cached_pdf
    false
  end

  # overridden in SimplyAccountingInvoice to skip tax setup
  def should_setup_taxes
    true
  end

  def reload(options=nil)
    @tax_amount = nil
    super
  end
  
  def update_payments
    if (self.paid != 0)
      self.pay_applications.each do |pa| 
        pa.payment.customer = self.customer
        pa.payment.save!
      end
    end
  end

  def invoice_or_quote
    self.meta_status ==  META_STATUS_QUOTE ? 'Quote' : 'Invoice'
  end
 

  #Make unique_number= and unique_name= private methods so that they can't be assigned directly.
  #instead, assign to virtual attribute unique
  protected
  def unique_number=(value)
    super
  end
  
  def unique_name=(value)
    super
  end

  def any_gateway_possible?
    created_by && !currency.blank?
  end

  public

  # deep clone (copies line items)
  def copy_data_from( orig )
    self.attributes = orig.attributes.except('id', 'calculated_at', 'updated_at', 'created_at', 'deleted_at', 'unique_number', 'unique_string')
    orig.line_items.each{|li| self.line_items << li.clone }
    self.schedule = orig.schedule
  end

  def self.create_recurring_from( proto, params )

    draft = proto.clone
    draft.copy_data_from proto

    draft.status = 'recurring'
    draft.build_schedule params
    draft.unique = nil

    return draft unless draft.valid?

    unless ['monthly', 'weekly', 'yearly'].include? draft.frequency.to_s
      draft.errors.add_to_base( "Frequency is invalid" )
      return draft
    end

    recurring = Invoice.create :created_by => draft.created_by
    recurring.unique = nil
    recurring.copy_data_from draft
    
    recurring.new_issue_due_dates!

    # iterate further so that we don't have recurring with past date
    user_date = draft.created_by.profile.tz_object.now.to_date
    recurring.new_issue_due_dates! while user_date > recurring.date

    recurring.generated_invoices << Invoice.find(proto.id)
    recurring.save!

    recurring
  end

  def self.recurring
    Invoice.find(:all, :conditions => "status = 'recurring'")
    #Invoice.with_scope :find=>{:conditions=>"status = 'recurring'"}
  end

  # A recurring invoice is due to generate a regular invoice
  # on scheduled day at 3 AM in user's local time zone
  public
  def recurring_generate_due_time
    local_time = Time.parse(self.date.to_s)
    local_time += 3.hours

    self.created_by.profile.tz_object.local_to_utc( local_time )
  end

  def new_issue_due_dates!

    prev_date = self.date
    due_offset = self.due_date ? (self.due_date - self.date).to_i : nil

    self.date ||= Date.today #FIXME: time zone awareness
    d = self.date

    case self.schedule.frequency.to_s
      when "yearly"
        d = d.next_year
      when "monthly"
        d = d.next_month
        d = d.end_of_month if (self.date == self.date.end_of_month)
      when "weekly"
        d += 7
      else
        raise "Invalid frequency"
    end

    self.date = d
    self.due_date = due_offset ? (self.date + due_offset) : nil

    self
  end

  protected
  
  def self.find_recurring_due_to_be_sent
    now = Time.now.utc
    Invoice.recurring.select {|i| now >= i.recurring_generate_due_time }
  end

  public
  def process_recurring!
#    self.unique = nil
    invoice = Invoice.create :created_by=>self.created_by

    invoice.copy_data_from self
   
    invoice.status = "draft"
    invoice.recurring_invoice_id = self.id
    #invoice.get_unique_number #TODO: discuss

    invoice.save!

    unless invoice.send_recipients.blank?
        delivery = Delivery.create :deliverable=>invoice, :created_by => invoice.created_by, :mail_name => 'send', :recipients => invoice.send_recipients
      if delivery.deliver! and delivery.save
        Activity.log_send!(delivery, invoice.created_by)
      else

      end
    end

    self.new_issue_due_dates!.save!

    #TODO: transaction
  end

  def self.process_recurring_invoices
    invoices = self.find_recurring_due_to_be_sent
    invoices.each { |i| i.process_recurring! }
  end

  def sendable_errors
    substitutions = [
                    {:field => :customer, :from=>"%{fn} can't be blank", :to=>N_("It has no customer. Please edit the invoice and add a customer.")},
                    {:field => :total_amount, :from=>"%{fn} must be greater than 0", :to=>N_("It has no line items. Please edit the invoice and add one or more line items.")}
                   ]

    errors = self.errors.instance_variable_get("@errors")
    substitutions.each do |subst|
      fieldname = subst[:field].to_s
      next if errors[fieldname].blank?
      if errors[fieldname].delete(subst[:from] )
        self.errors.add_to_base( subst[:to])
      end
    end      
  end

  delegate :send_recipients, :frequency, :to=>:schedule, :allow_nil => true

end
