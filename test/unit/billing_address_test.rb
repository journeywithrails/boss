require File.dirname(__FILE__) + '/../test_helper'

class BillingAddressTest < ActiveSupport::TestCase
  include Sage::BusinessLogic::Exception

# create billing address tests
  
  def test_validate_fields
    ba = BillingAddress.new
    assert_equal [:name, :address1, :city, :state, :zip, :country, :phone, :email], ba.validate_fields
  end

  def test_validate_fields_changed
    ba = BillingAddress.new
    ba.validate_fields = [:name, :city]
    assert_equal [:name, :city], ba.validate_fields
  end

  def test_validate
    ba = BillingAddress.new
    ba.validate_fields = [:name, :city]
    assert(ba.validate?(:name))
    deny(ba.validate?(:zip))
  end

  def test_valid
    ba = BillingAddress.new
    ba.validate_fields = [:name, :city]
    ba.name = 'Joe'
    ba.city = 'Halifax'
    assert(ba.valid?)
  end

  def test_invalid
    ba = BillingAddress.new
    ba.validate_fields = [:name, :city]
    ba.name = 'Joe'
    ba.zip = '90210'
    deny(ba.valid?)
  end
end
