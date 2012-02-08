class Contact < ActiveRecord::Base
  attr_accessor :row_id # RADAR view coupling
  
  belongs_to :customer
    
  def self.find_for_select
    self.find(:all).collect {|c| [ c.name, c.id ] }
  end  
  
  validates_format_of :first_name, :with => /\A[^,<>()\[\]]*\Z/, :message => N_('Name may not contain ,()<>[]'), :allow_nil => true
  validates_format_of :last_name, :with => /\A[^,<>()\[\]]*\Z/, :message => N_('Name may not contain ,()<>[]'), :allow_nil => true

  validates_email_format_of :email, :message => N_('must be a valid email address.'), :allow_nil => true

  before_validation :purge_blank_email
  
  def purge_blank_email
    if self.email.blank?
      self.email = nil
    end
  end
  
  def name
    str = [self.first_name, self.last_name].compact.join(" ")
    str.blank? ? self.email : str
  end

  def is_default?
    return false if self.new_record?
    self.customer.default_contact.id == self.id
  end
  alias_method :is_default, :is_default?


  #RADAR  ugliness. See CustomersController
  attr_accessor :set_as_default_contact
  
  before_destroy :null_out_customer_default_contact
  def null_out_customer_default_contact
    if self.customer.default_contact == self
      self.customer.update_attribute(:default_contact_id, nil)
    end
  end
  
  def self.find_fuzzy(term, options={})
    #TODO should eventually be replaced with ferret
    term.downcase!
    term.tr!( '*?', '%_' )
    name_term = term
    email_term = term
    name_term = term + '%' unless term.include?('%')
    email_term = '%' + term + '%' unless term.include?('%')
    name_term = Contact.quote_value(name_term)
    email_term = Contact.quote_value(email_term)
    conditions = "last_name like #{name_term} or first_name like #{name_term} or email like #{email_term}"
    if options[:conditions]
      conditions = [options[:conditions], conditions].join(' AND ')
    end
    options[:conditions] = conditions
    options[:order] ||= 'customer_id, first_name, last_name, email'
    self.find(:all, options)
  end
  
  def formatted_email
    "#{self.name} <#{self.email}>"
  end
  
end
