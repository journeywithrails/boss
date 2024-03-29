
class Customer < ActiveRecord::Base
  
  has_many :invoices, :order => "created_at" #TODO: check if this is correct according to business rules
  has_many :payments, :order => "created_at"
  has_many_with_attributes :contacts, 
      {:not_found_exception => Sage::ActiveRecord::Exception::OutOfScope},
      {:dependent => :delete_all, :order => "created_at" } #TODO: check if this is correct according to business rules
  belongs_to :created_by, :class_name => 'User', :foreign_key => :created_by_id
  belongs_to :default_contact, :class_name => 'Contact', :foreign_key => :default_contact_id
  has_many :taxes, :as => :taxable, :class_name => 'Tax', :dependent => :delete_all
  include ::Tax::TaxesVersionOne
  
  # attr_protected :created_by_id, :default_contact_id, :simply_guid
   
  validates_presence_of   :created_by_id

  validates_presence_of   :name, :message => N_(" - Customer name is required.")
  

  validates_length_of     :address1, :maximum => 255, :allow_nil => true, :message => N_(" - Address 1 maximum length is 255 characters.")
  validates_length_of     :address2, :maximum => 255, :allow_nil => true, :message => N_(" - Address 2 maximum length is 255 characters.")  
  validates_length_of     :city, :maximum => 255, :allow_nil => true, :message => N_(" - City maximum length is 255 characters.")  
  validates_length_of     :province_state, :maximum => 255, :allow_nil => true, :message => N_(" - Province/State maximum length is 255 characters.")  
  validates_length_of     :postalcode_zip, :maximum => 255, :allow_nil => true, :message => N_(" - Postal Code/Zip maximum length is 255 characters.")    
  validates_length_of     :country, :maximum => 255, :allow_nil => true, :message => N_(" - Country maximum length is 255 characters.")      
  validates_length_of     :website, :maximum => 255, :allow_nil => true, :message => N_(" - Website maximum length is 255 characters.")  
  validates_length_of     :phone, :maximum => 255, :allow_nil => true, :message => N_(" - Phone maximum length is 255 characters.")  
  validates_length_of     :fax, :maximum => 255, :allow_nil => true, :message => N_(" - Fax maximum length is 255 characters.")   
  
  validates_length_of     :simply_guid, :is => 32, :allow_nil => true #TODO: do we need STI for customer?
  
  validates_associated    :contacts
  before_save             :cleanup_guid
  after_create            :ensure_default_contact_back_reference
  acts_as_configurable
  

  include CountrySettings
  include SimplyModelIntegration

  alias_method :old_default_contact, :default_contact
  
  def validate
    #FIXME: the sql statements fail when customer names contain a single quote char
    if self.simply_guid.blank?
      if !self.new_record?
        customers = Customer.find_by_sql(["SELECT * FROM customers WHERE created_by_id = ? AND name = ? AND (simply_guid = '' OR simply_guid IS NULL) AND id != ?", self.created_by_id, self.name, self.id])
      else
        customers = Customer.find_by_sql(["SELECT * FROM customers WHERE created_by_id = ? AND name = ? AND (simply_guid = '' OR simply_guid IS NULL) ", self.created_by_id, self.name])        
      end 
      
      if !customers.blank?
        errors.add('name',  _("Customer name already exists"))
      end
    end
  end
  
  def cleanup_guid
    if self.simply_guid.blank?
      self.simply_guid = nil
    end
  end
  
  def self.find_for_select
    self.find(:all, :order => 'name').collect {|c| [ c.name, c.id ] }
  end

  def default_contact
    return old_default_contact unless old_default_contact.nil?
    contacts.first
  end
  alias_method :contact, :default_contact
  

  alias_method :old_default_contact=, :default_contact=
  def default_contact=(new_contact)
    case new_contact
    when Hash
      contact = self.contacts.build(new_contact)
      self.default_contact_id = nil
      self.old_default_contact = contact #RADAR the 'self' is definitely required here
    when Contact
      self.contacts << new_contact
      self.old_default_contact = new_contact
    end
  end
  
  
  def amount_owing
    self.invoices.find(:all,:conditions => "status NOT IN('superceded','quote_draft','quote_sent') ").inject(BigDecimal.new('0.0')) do |sum, i|
      sum + i.amount_owing
    end
  end
  
  def self.filtered_customers(parent, filters)
    conditions = []
    unless filters.name.blank?
      conditions << "name like (\"%#{filters.name}%\")"
    end

    unless filters.contact_name.blank?
      conditions << "CONCAT(contacts.first_name, ' ', contacts.last_name) LIKE (\"%#{filters.contact_name}%\")"
    end
    
    unless filters.contact_phone.blank?
      conditions << "contacts.phone like (\"%#{filters.contact_phone}%\")"
    end
    
    unless filters.contact_email.blank?
      conditions << "contacts.email like (\"%#{filters.contact_email}%\")"
    end
    
    condition_str = conditions.empty? ? nil : '(' + conditions.join(') AND (') + ')'

        
#     Customer.with_scope(:find => {:conditions => condition_str,
# #                          :joins => "left join contacts on contacts.customer_id = customers.id",
#  #                         :select => "distinct customers.*"
#                           }) do
#       parent.find(
#                         :all,
#                         :page => filters.page
#                         )
#     end

    parent.find(:all,
                :conditions => condition_str,
                :include => [:contacts],
                :page => filters.page
    )
  end

  def contact_name
    self.default_contact.nil? ? '-' : default_contact.name
  end
  
  def contact_name=(value)
    if default_contact.nil?
      self.create_default_contact
    end
    names = value.split(/, */)
    case names.length
    when 1
      self.default_contact.first_name = names[0]
    when 2
      self.default_contact.first_name = names[1]
      self.default_contact.last_name = names[0]
    else
      self.default_contact.first_name = value
    end
    value
  end
  
  def contact_email
    self.default_contact.nil? ? '-' : default_contact.email
  end
  
  def self.list_json_params
    { :only    => [:customers, :id, :name, :phone, :created_at, :total], 
      :methods => [:contact_email, :contact_name,:amount_owing] }
  end

  def prune_empty_contacts(reload=false)
    self.contacts.each {|contact| 
      if contact.first_name.blank? and 
         contact.last_name.blank? and 
         contact.email.blank?  
        contact.destroy 
       end
    self.contacts(true) if reload
    }
  end 

  # it peeves me that this is necessary.
  def ensure_default_contact_back_reference
    if self.default_contact
      unless self.default_contact.customer_id == self.id
        self.default_contact.customer_id = self.id
        self.default_contact.save(false)
      end
    end
  end

  # used by simply integration
  def processable?
    puts "checking processable? for customer" if $log_on
    puts "\nbefore valid_for_attributes errors: #{errors.inspect}" if $log_on
    processable = self.valid_for_attributes?(self.class.column_names - ["created_by_id", "created_by"])
    puts "\nafter valid_for_attributes errors: #{errors.inspect}" if $log_on
    processable
  end
    
  def inherit_tax(key, taxable, inherit_enabled=true)
    parent_tax = self.tax_for_key(key)
    if parent_tax.nil?
      self.created_by.inherit_tax(key, taxable, inherit_enabled)
    else
      taxable.taxes << parent_tax.new_copy(:enabled => (parent_tax.enabled and inherit_enabled))
    end
  end
end
