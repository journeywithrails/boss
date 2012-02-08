# Use this class when passing money values to active merchant. It is inconsistent
# about whether it uses dollars or cents but if you explicitly use this class
# you can be certain it will use the correct value.

class Cents
  def initialize(value_hash)
    if value_hash.is_a?(Hash)
      if value_hash.key?(:cents) and value_hash.key?(:dollars)
        raise "Initialize Cents with either dollars or cents but not both."
      elsif not value_hash.key?(:cents) and not value_hash.key?(:dollars)
        raise "Cents object must be initiated with a hash of either dollars or cents."
      end
      if value_hash[:cents]
        @cents = value_hash[:cents].to_i
      elsif value_hash[:dollars]
        @cents = (value_hash[:dollars] * 100).to_i
      else
        @cents = 0
      end
    else
      raise "Cents object must be initiated with a hash of either dollars or cents."
    end
  end

  def cents
    @cents
  end

  def ==(other)
    if other.is_a? Cents
      other.cents == cents
    end
  end
end

