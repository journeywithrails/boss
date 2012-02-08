class BillingAddress < ActiveRecord::BaseWithoutTable
  Fields = [:name, :address1, :address2, :city, :state, :zip, :country, :phone, :fax, :email]

  Fields.each do |name|
    column name
    validates_presence_of(name, :if => proc { |o| o.validate?(name) })
  end

  include CountrySettings
  
  attr_accessor :validate_fields
  attr_accessor :exclude_fields

  def validate_fields=(fields)
    @validate_fields = fields
  end

  def validate_fields
    # by default validate everytihng except address2 and fax
    @validate_fields ||= (Fields - [:address2, :fax])
  end

  def exclusive_fields=(fields)
    self.exclude_fields = (Fields - fields)
  end

  def exclude_fields=(fields)
    validate_fields.reject! do |field|
      fields.include?(field)
    end
    @exclude_fields = fields
  end

  def exclude?(field)
    if exclude_fields
      exclude_fields.include?(field)
    end
  end

  def validate?(field)
    validate_fields.include?(field)
  end
end
