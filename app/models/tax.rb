class Tax < ActiveRecord::Base
  module TaxesVersionOne

    def self.tax_keys
      %w{tax_1 tax_2}
    end
    
    def self.each_tax_key
      ::Tax::TaxesVersionOne.tax_keys.each { |key| yield key }
    end
    
    def self.accessible_tax_attributes
        %w{rate name enabled}.each { |attr| yield attr }
    end

    def self.all_accessible_tax_attributes
      ::Tax::TaxesVersionOne.each_tax_key do |key|
        ::Tax::TaxesVersionOne.accessible_tax_attributes do |attr|
          yield "#{key}_#{attr}"
        end
      end
    end

    def tax_for_key(key)
      self.taxes.detect{|tax| tax.profile_key == key}
    end

    # this method is used when parsing simply invoice. It expects an array of taxes,
    # and it sets the profile_key based on the index of the tax
    def build_taxes_with_attributes(attrs, rejecting=false)
      raise Sage::BusinessLogic::Exception::IncorrectDataException, 
        "Tax attributes should be an array of taxes" unless attrs.is_a?(Array)
      
      raise Sage::BusinessLogic::Exception::IncorrectDataException, 
        "Taxes Version One can handle only 2 taxes but received #{attrs.size} taxes" if attrs.size > 2
        
      attrs.each_with_index do |attrs, index|
        # has_many proxy is not working with STI
        tax = Tax.new
        self.taxes << tax        
        good_params = ( rejecting ? tax.reject_unknown_attributes(attrs) : attrs )
        tax.attributes = good_params
        tax.profile_key = ::Tax::TaxesVersionOne.tax_keys[index]
      end
    end
    
    def get_or_build_tax_for_key(key)
      # tax = self.taxes.find_by_profile_key(key).# 2 reasons not to do this: 1. find_by_profile_key will not work for taxes that have already been built but not saved yet. 2. find_by_profile_key will return DIFFERENT OBJECTS than taxes.each (!). Change one and save the other and waste time debugging why your changes don't get saved
      tax = self.taxes.detect{|t| t.profile_key == key} 
      tax ||= self.taxes.build(:profile_key => key)
      if tax.taxable.blank?
        the_profile = profile || user_record.profile
        tax.taxed_on = 'tax_1' if key == 'tax_2' && the_profile.tax_1_in_taxable_amount == true
      end
      tax
    end
    
    ::Tax::TaxesVersionOne.each_tax_key do |key|
      define_method key do
        self.tax_for_key(key)
      end
      %w{rate name enabled}.each do |attr|
        define_method "#{key}_#{attr}" do
          self.send(key).send(attr)
        end 
        define_method "#{key}_#{attr}=" do |value|
          value = nil if value.blank? # in profile, taxes are disabled by setting name & rate to blank
          tax = self.get_or_build_tax_for_key(key)
          tax.send("#{attr}=", value)
        end 
      end
    end

    def validate_taxes(auto_enable=false)
      ::Tax::TaxesVersionOne.each_tax_key do |tax_profile_key|
        tax = self.tax_for_key(tax_profile_key)
        unless tax.nil?
          tax.auto_enable if auto_enable #hack to disable a tax when both rate & name are set to blank
          if tax.enabled
            unless tax.valid?
              %w{name rate}.each do |attr|
                self.errors.add("#{tax_profile_key}_#{attr}", tax.errors[attr]) unless tax.errors[attr].nil?
              end
              self.errors.add(tax_profile_key, tax.errors[:base]) unless tax.errors[:base].nil?
            end
          end
        end
      end
    end    
  end

  attr_accessor :effective_rate
  
  belongs_to :taxable, :polymorphic => true
  belongs_to :created_by, :class_name => 'User', :foreign_key => :created_by_id
  belongs_to :parent, :class_name => 'Tax', :foreign_key => :parent_id  
  acts_as_tree :order => :id
  
  validates_numericality_of :rate, :greater_than => 0, :if => :enabled ,:message => N_("must be a number. Please enter a valid number greater than 0.")
  validates_presence_of :name, :if => :enabled, :message => N_("can't be blank if tax is enabled")
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :allow_nil => true
  
  def validate
    errors.add("profile_key", "should not change") unless parent.nil? or (profile_key == parent.profile_key)
  end
  
  def new_copy(attributes={})
    tax_copy = Tax.new
    tax_copy.rate = self.rate
    tax_copy.name = self.name
    tax_copy.profile_key = self.profile_key
    tax_copy.included = self.included
    tax_copy.created_by = self.created_by
    tax_copy.parent = self
    tax_copy.enabled = self.enabled
    tax_copy.amount = nil
    tax_copy.attributes = attributes unless attributes.nil?
    tax_copy
  end
  
  # return a hash of attributes that are different from the parent tax IFF this tax was edited
  def changed_attributes
    attributes = HashWithIndifferentAccess.new
    
    if self.edited
      %w{rate name}.each do |attr|
        if self.different?(attr)
          attributes[attr] = self.send(attr)
        end
      end
    end
    attributes
  end
  
  def rate_changed?
    !edited and self.different?(:rate)
  end
  
  def name_changed?
    !edited and self.different?(:name)
  end

  def rate=(value)
    value = 0 if value.blank?
    write_attribute('rate', value)
    self.edited = (not parent.nil?)
  end
  
  def name=(value)
    write_attribute('name', value)
    self.edited = (not parent.nil?)
  end
  
  def name_roughly
    return nil if self.name.nil?
    self.name.downcase.gsub('.', '')
  end
  
  def auto_enable
    RAILS_DEFAULT_LOGGER.debug "\n--------------- auto_enable  #{self.profile_key} was: #{self.enabled}---------------------"
    self.enabled = ! (self.name.blank? and (self.rate.nil? or self.rate == 0))
    RAILS_DEFAULT_LOGGER.debug "now is: #{self.enabled}"
  end
  
  protected
  def different?(attr)
    ancestor = self
    while (ancestor = ancestor.parent)
      return true if ancestor.send(attr) != self.send(attr)
    end
    return false
  end
end
