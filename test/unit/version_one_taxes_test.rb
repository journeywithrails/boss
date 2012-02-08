require File.dirname(__FILE__) + '/../test_helper'

class VersionOneTaxesTest < Test::Unit::TestCase
  # tests the module ::Tax::TaxesVersionOne, using user object
  fixtures :taxes, :users
  def setup
  end
  
  def teardown
  end
  
  def test_should_walk_set_of_tax_1_and_tax_2
    names = Set.new
    ::Tax::TaxesVersionOne.each_tax_key{|name| names << name}
    assert_equal Set.new(['tax_1', 'tax_2']), names, "::Tax::TaxesVersionOne.each_tax_key should return tax_1 and tax_2"
  end
  
  def test_should_return_accessible_tax_attributes
    # these are the attributes of tax that the user can edit
    attrs = Set.new
    ::Tax::TaxesVersionOne.accessible_tax_attributes{|attr| attrs << attr}
    assert_equal Set.new(['name', 'rate', 'enabled']), attrs, "accessible_tax_attributes should return name, rate, enabled"
  end
  
  def test_should_return_tax_for_key
    u = User.new
    u.save(false)
    u.taxes.build(:profile_key => 'bob', :name => 'i_am_bob')
    u.taxes.build(:profile_key => 'mary', :name => 'i_am_mary')
    u.taxes.each{|t| t.save(false)}

    assert_nil u.tax_for_key('ralph'), "tax_for_key failed to return nil for non-existant key"
    assert u.tax_for_key('bob'), "tax_for_key failed to return the tax object with profile_key == bob"
    assert_equal 'i_am_bob', u.tax_for_key('bob').name, "tax returned by tax_for_key was missing name attribute"
        
  end

  def test_tax_for_key_should_return_in_memory_values
    u = User.new
    u.save(false)
    u.taxes.build(:profile_key => 'bob', :name => 'i_am_bob')
    u.taxes.build(:profile_key => 'mary', :name => 'i_am_mary')
    u.taxes.each{|t| t.save(false)}
    assert u.tax_for_key('bob'), "tax_for_key failed to return the tax object with profile_key == bob"
    bob_id = u.tax_for_key('bob').id
    bob = Tax.find(bob_id)
    bob.name = 'changed'
    bob.save(false)
    assert_equal 'i_am_bob', u.tax_for_key('bob').name, "tax returned by tax_for_key was not the in memory value"
    u.taxes.each{|t| t.name = 'in_memory'}
    assert_equal 'in_memory', u.tax_for_key('bob').name, "tax returned by tax_for_key was not the in memory value"
    u.reload
    assert_equal 'changed', u.tax_for_key('bob').name, "after user.reload, tax returned by tax_for_key was not the saved value"
  end
  
  def test_should_get_or_build_tax_for_key
    u = User.new
    assert u.taxes.empty?, "brand new user did not have empty taxes"
    
    u.get_or_build_tax_for_key('bob')
    
    deny u.taxes.empty?, "after get_or_build_tax_for_key user taxes was empty"
    assert_equal 1, u.taxes.length, "after get_or_build_tax_for_key user taxes did not have length 1"

    assert_no_difference 'Tax.count', "get_or_build_tax_for_key added a new tax" do
      u.get_or_build_tax_for_key('bob')
    end

    assert_equal 1, u.taxes.length, "after get_or_build_tax_for_key for existing key, user taxes did not have length 1"
    assert_equal 0, u.taxes.count, "after get_or_build_tax_for_key for existing key, user taxes did not have count 0"
    
    assert_no_difference 'Tax.count', "get_or_build_tax_for_key added a new tax" do
      u.get_or_build_tax_for_key('bob').attributes = {:name => 'test', :rate => BigDecimal("4.0")}
    end

    assert_difference 'Tax.count', 1, "after making tax valid, saving user didn't save it" do
      u.save(false)
    end


    assert_equal 1, u.taxes.length, "after get_or_build_tax_for_key for existing key and saving, user taxes did not have length 1"
    assert_equal 1, u.taxes.count, "after get_or_build_tax_for_key for existing key and saving, user taxes did not have count 1"
  end
  
  def test_setting_tax_1_rate_should_build_new_tax_or_set_rate_of_existing_tax
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    assert_nothing_raised "setting tax_1_rate on new user raised an error" do
      u.tax_1_rate = "3.5"
    end
    
    deny u.taxes.empty?, "after setting tax_1_rate taxes on user was empty"
    
    assert_equal BigDecimal("3.5"), u.taxes.first.rate, "after setting tax_1_rate the tax in user did not have the set rate"
    assert_equal 'tax_1', u.taxes.first.profile_key, "after setting tax_1_rate the tax in user did not have profile_key tax_1"
  end

  def test_setting_tax_2_rate_should_build_new_tax_or_set_rate_of_existing_tax
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    assert_nothing_raised "setting tax_2_rate on new user raised an error" do
      u.tax_2_rate = "3.5"
    end
    
    deny u.taxes.empty?, "after setting tax_2_rate taxes on user was empty"
    
    assert_equal BigDecimal("3.5"), u.taxes.first.rate, "after setting tax_2_rate the tax in user did not have the set rate"
    assert_equal 'tax_2', u.taxes.first.profile_key, "after setting tax_2_rate the tax in user did not have profile_key tax_2"
  end

  def test_setting_tax_1_name_should_build_new_tax_or_set_name_of_existing_tax
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    assert_nothing_raised "setting tax_1_name on new user raised an error" do
      u.tax_1_name = "test_tax"
    end
    
    deny u.taxes.empty?, "after setting tax_1_name taxes on user was empty"
    
    assert_equal "test_tax", u.taxes.first.name, "after setting tax_1_name the tax in user did not have the set name"
    assert_equal 'tax_1', u.taxes.first.profile_key, "after setting tax_1_name the tax in user did not have profile_key tax_1"
  end

  def test_setting_tax_2_name_should_build_new_tax_or_set_name_of_existing_tax
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    assert_nothing_raised "setting tax_2_name on new user raised an error" do
      u.tax_2_name = "test_tax"
    end
    
    deny u.taxes.empty?, "after setting tax_2_name taxes on user was empty"
    
    assert_equal "test_tax", u.taxes.first.name, "after setting tax_2_name the tax in user did not have the set name"
    assert_equal 'tax_2', u.taxes.first.profile_key, "after setting tax_2_name the tax in user did not have profile_key tax_2"
  end

  def test_setting_tax_1_enabled_should_build_new_tax_or_set_enabled_of_existing_tax
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    assert_nothing_raised "setting tax_1_enabled on new user raised an error" do
      u.tax_1_enabled = true
    end
    
    deny u.taxes.empty?, "after setting tax_1_enabled taxes on user was empty"
    
    assert u.taxes.first.enabled, "after setting tax_1_enabled the tax in user did not have the set enabled"
    assert_equal 'tax_1', u.taxes.first.profile_key, "after setting tax_1_enabled the tax in user did not have profile_key tax_1"
  end

  def test_setting_tax_2_enabled_should_build_new_tax_or_set_enabled_of_existing_tax
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    assert_nothing_raised "setting tax_2_enabled on new user raised an error" do
      u.tax_2_enabled = true
    end
    
    deny u.taxes.empty?, "after setting tax_2_enabled taxes on user was empty"
    
    assert u.taxes.first.enabled, "after setting tax_2_enabled the tax in user did not have the set enabled"
    assert_equal 'tax_2', u.taxes.first.profile_key, "after setting tax_2_enabled the tax in user did not have profile_key tax_2"
  end

  def test_validate_taxes_should_do_nothing_if_taxes_empty
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    assert_nothing_raised do
      u.validate_taxes
    end
    assert u.errors.empty?
  end
  
  def test_validate_taxes_should_do_nothing_if_taxes_disabled
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    u.tax_1_rate = 2
    u.tax_1_enabled = false
    u.tax_2_rate = 2
    u.tax_2_enabled = false
    assert_nothing_raised do
      u.validate_taxes
    end
    assert u.errors.empty?
  end
  
  def test_validate_taxes_should_set_errors_on_tax_owner
    u = User.new
    u.save(false)
    assert u.taxes.empty?, "taxes of new user was not empty"
    
    u.tax_1_rate = 2
    u.tax_1_enabled = true
    u.tax_2_rate = 2
    u.tax_2_enabled = true
    assert_nothing_raised do
      u.validate_taxes
    end
    deny u.errors.empty?, "after calling user.validate_taxes with some invalid taxes, user errors were empty"
    assert_not_nil u.errors[:tax_1_name], 'after calling user.validate_taxes when tax_1_name was unset, errors did not have an error for tax_1_name'
    assert_not_nil u.errors[:tax_2_name], 'after calling user.validate_taxes when tax_2_name was unset, errors did not have an error for tax_2_name'
    
    u.errors.clear
    
    u.tax_1_rate = nil
    u.tax_1_name = "bob"
    u.tax_2_name = "mary"

    assert_nothing_raised do
      u.validate_taxes
    end
    deny u.errors.empty?, "after calling user.validate_taxes with some invalid taxes, user errors were empty"
    assert_not_nil u.errors[:tax_1_rate], 'after setting tax_1_rate to nil and calling user.validate_taxes, errors did not have an error for tax_1_rate'
    assert_nil u.errors[:tax_2_name], "after setting tax_2_name and calling user.validate_taxes, errors still had an error for tax_2_name"
    assert_nil u.errors[:tax_2_rate], "after setting tax_2_rate and calling user.validate_taxes, errors still had an error for tax_2_rate"
  end
  
  
  
end 
