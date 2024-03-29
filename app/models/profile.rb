# A model without backend table. All attributes are virtual and setting with
# any name can be stored. Actual values are stored using acts_as_configurable

class Profile < ActiveRecord::BaseWithoutTable
  # BaseWithoutTable should never include Validateable

  attr_accessor   :user_record
  
  # define all preference here first
  # NOTE: version one taxes attributes are defined in a block by asking Tax::TaxesVersionOne for all_accessible_tax_attributes
  attr_accessible :company_setting, :company_name,:user_record, :company_address1, :company_address2,
    :company_city,:company_state,:company_country,:company_postalcode,:company_phone,:company_fax, :logo_image, 
    :tax_enabled, :discount_before_tax, :theme, :company_website, :currency, :contact_name, :mail_opt_in,
		:default_comment_for_quote, :default_comment_for_invoice, :heard_from, :heard_from_specific, :time_zone, :last_invoice_template, :venture_1_id,
    :tax_1_in_taxable_amount

  include CountrySettings
  include Tax::TaxesVersionOne
  
  Tax::TaxesVersionOne.all_accessible_tax_attributes {|attr| attr_accessible attr.to_sym }
  delegate :taxes, :to => :user_record
  
  def tz
    if time_zone.nil?
      return "GMT"
    else
      return time_zone
    end
  end
  
  def tz_object
    TZInfo::Timezone.get( self.tz )
  end

  def all_tax_names_blank?
    self.taxes.each do |t|
      if !self.tax_enabled || !t.name.blank?
        return false
      end
    end
    #all tax names blank
    self.tax_enabled = false
    return true
  end
  
  def dirty_cache
    self.user_record.pdf_dirty_cache
  end
    
  # remember we are inheriting from ActiveRecord.Base through BaseWithoutTable. So if we override things we must use super!
  def initialize(user, attributes={})
    super(attributes)
    self.user_record = user
  end  
  
  # the country accessor method is used by CountrySettings
  def country
    RAILS_DEFAULT_LOGGER.debug("profile.country -- returning #{setting(:company_country)}")
    
    setting(:company_country).to_s
  end
  
  def country=(value)
    self.company_country=value
  end
    
  def company_country=(value)
    set_setting(:company_country, value.to_s)
    self.currency = Currency.currency_for_country( value )
  end
    
  # RADAR specific to TaxesVersionOne
  def tax_1
    get_or_build_tax_for_key("tax_1")
  end
  
  # RADAR specific to TaxesVersionOne
  def tax_2
    get_or_build_tax_for_key("tax_2")
  end

  def mail_opt_in=(value)
    set_setting_boolean(:mail_opt_in, value)
  end

  def mail_opt_in
    setting_default_true(:mail_opt_in)
  end
  
  def tax_enabled=( value )
    @dirty_taxes = true
    b_value = set_setting_boolean(:tax_enabled, value)
    user_record.taxes.each{|tax| tax.enabled = b_value}
  end
    
  def tax_enabled
    setting_default_true(:tax_enabled)
  end
  
  def discount_before_tax=( value )
    set_setting_boolean(:discount_before_tax, value)
  end
  
  def currency
    if setting(:currency).blank?
      Currency.currency_for_country( self.company_country )
    else
      setting(:currency)
    end
  end
    
  def currency=( value )
    if Currency.valid_currency?(value)
      set_setting(:currency, value)
    else
      set_setting(:currency, Currency.default_currency)
    end
  end
  
  def theme
    setting(:theme) || 'Default'
  end
  
  def theme=( value )
    set_setting(:theme, value) if Theme.valid?(value)
  end
    
  def discount_before_tax
    setting_default_true(:discount_before_tax)
  end
    
  def tax_1_in_taxable_amount=( value )
    set_setting_boolean(:tax_1_in_taxable_amount, value)
  end

  def tax_1_in_taxable_amount
    setting_default_false(:tax_1_in_taxable_amount)
  end

  def setting(key)
    a = @attributes_cache[key.to_sym]
    return a unless a.nil?
    return user_record.settings[key.to_sym]
  end
  
  def set_setting(key, value)
    @attributes_cache[key.to_sym] = value
  end
  
  def set_setting_boolean(key, value)
    if value and value != "false" and value != "0"
      set_setting(key, true)
    else
      set_setting(key, false)
    end
  end
  
  def setting_default setting
    return true if setting.is_a?TrueClass
    return false if setting.is_a?FalseClass
    return !!(setting.value) if setting.responds_to?(:value)
    return !!setting
  end

  def setting_default_true(key)
    s = setting(key)
    return true if s.nil?
    return setting_default(s)
  end

  def setting_default_false(key)
    s = setting(key)
    return false if s.nil?
    return setting_default(s)
  end
  
  def method_missing(meth, *args, &block)
    if /=$/=~(meth=meth.id2name) then 
      # this is bad because it breaks crud cycle
       # user_record.settings[meth[0...-1]] = (args.length<2 ? args[0] : args)
       set_setting(meth[0...-1], (args.length<2 ? args[0] : args))
    else
       setting(meth)
    end    
  end
  
  def is_heard_from_complete?
    if (self.heard_from == "other" && self.heard_from_specific.blank?) or self.heard_from.blank?
      return false
    else
      return true
    end
  end
  
  def is_complete?
    
    # return false unless (!self.heard_from.blank?)
    return false unless (!self.company_name.blank? || !self.contact_name.blank?)
    return false unless (!self.company_address1.blank? || !self.company_address2.blank?)
    return false unless (!self.company_city.blank? && !self.company_country.blank?)
    
    if ["CA", "US"].include?(self.company_country)
      return false unless ( !self.company_postalcode.blank? && !self.company_state.blank? )
    end
    
    return true
  end
  
  def logo
    return user_record.logo
  end
  
  # to just returns nil and the web invoice will use the default css 
  def web_invoice_css
    return nil
  end
  
  def current_view
   # lazily initialize current_view
   update_attribute(:current_view, :biller) if setting(:current_view).nil? 
   setting(:current_view).to_sym # handle old form of current_view which was a string
  end
 
  def update_attribute(key, value) # unlike the real update_attribute, this ONLY saves the specified attribute!!!
    set_setting(key, value)
    user_record.settings[key] = value    
  end
  
  # we need to delegate saving the taxes
  def save(perform_validation=true)
    all_tax_names_blank?

    # RADAR specific to TaxesVersionOne
    result = super(perform_validation)
    if perform_validation
      if self.valid?
        perform_save
        # handle the fact that taxes in profile are disabled by setting them to blank rather than by checkbox
        taxes.each(&:auto_enable) if self.tax_enabled 
        result &&= save_taxes
      end
    else
      perform_save
      result &&= save_taxes
    end
    result
  end
  
  def perform_save
    @attributes_cache.each{|k,v| user_record.settings[k] = v}
  end
  
  def save_taxes
    taxes.inject(true){|result, tax| result && tax.save}
  end
  
  def save!
    # RADAR specific to TaxesVersionOne
    super
    if self.tax_enabled
      taxes.each(&:auto_enable) # handle the fact that taxes in profile are disabled by setting them to blank rather than by checkbox
      taxes.each(&:save!)
    end
    perform_save    
  end

  def reload(options = nil)
    super
    user_record.reload
  end
  
  def sections
    list = ["addressing", "taxes", "logo", "communications", "payments"]
    (list << "theme") if !::AppConfig.hide_theme
    return list
  end

  protected


  def validate
    # Tax Rates
    if tax_enabled
      # RADAR specific to TaxesVersionOne
      # if tax_enabled is true, make sure taxes are there
      tax_1
      tax_2
      validate_taxes(true)
    end

    if self.heard_from == "other" && self.heard_from_specific.blank?
      self.errors.add('', _("Please select an answer for \"How did you hear about Billing Boss?\""))
    end
    
    if self.user_record.new_record? && self.user_record.signup_type == 'rac'
      self.errors.add('', _('Please fill out all address information')) unless self.is_complete?
    end

  end

  def confirm_changes=(value)
    set_setting_boolean(:confirm_changes, value)
  end

  def confirm_changes
    setting_default_true(:confirm_changes)
  end
  
end
