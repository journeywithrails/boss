require File.dirname(__FILE__) + '/../test_helper'
include Sage::BusinessLogic::Exception

class TaxTest < Test::Unit::TestCase
  
  def test_should_create_a_new_copy
    root = Tax.new(
      :included => false,
      :rate => BigDecimal("4.1"),
      :name => "bob's tax",
      :profile_key => "tax_1",
      :amount => BigDecimal("123"),
      :enabled => false
    )
    
    child = root.new_copy
    
    assert_equal BigDecimal("4.1"), child.rate, "after creating a tax with new_copy, the rate should be same as the original tax"
    assert_equal "bob's tax", child.name, "after creating a tax with new_copy, the name should be same as the original tax"
    assert_equal "tax_1", child.profile_key, "after creating a tax with new_copy, the profile_key should be same as the original tax"
    assert_equal root, child.parent, "parent should be the tax we asked for a copy"
    assert_nil child.amount, "amount should be nil even though parent had an amount"
    deny child.enabled, "after creating a tax with new_copy, enabled should be same as the original tax"
  end
  
  def test_should_create_a_new_copy_with_overrides
    root = Tax.new(
      :included => false,
      :rate => BigDecimal("4.1"),
      :name => "bob's tax",
      :profile_key => "tax_1",
      :enabled => true
    )
    
    child = root.new_copy(:name => 'howdy')
    
    assert_equal BigDecimal("4.1"), child.rate, "after creating a tax with new_copy, the rate should be same as the original tax"
    assert_equal "howdy", child.name, "after creating a tax with new_copy, the name should be same as the original tax"
    assert_equal "tax_1", child.profile_key, "after creating a tax with new_copy, the profile_key should be same as the original tax"
    assert_equal root, child.parent, "parent should be the tax we asked for a copy"
    assert child.enabled, "after creating a tax with new_copy, enabled should be same as the original tax"

  end
  
  def test_should_track_edited_from_parent_value
    root = Tax.new(:rate => BigDecimal("4.1"), :name => 'bob')
    child_1 = root.new_copy
    deny child_1.edited, "by default edited should be false"
    child_1.name = "mary"
    assert child_1.edited, "after changing name edited should be true"    
    child_2 = root.new_copy
    child_2.rate = "2.7"
    assert child_2.edited, "after changing name edited should be true"    
  end

  def test_should_recognize_when_ancestor_rate_changes
    root = Tax.new(:rate => BigDecimal("4.1"))
    child_1 = root.new_copy
    deny child_1.rate_changed?, "child tax should not be rate_changed? when root rate is unchanged"
    root.rate = BigDecimal("6.2")
    assert child_1.rate_changed?, "child tax should be rate_changed? when root rate is different"
    child_1.rate = BigDecimal("6.2")
    deny child_1.rate_changed?, "child tax should not be rate_changed? when root rate is not different"
    root.rate = BigDecimal("7")
    deny child_1.rate_changed?, "child tax should not be rate_changed? when root rate is different and child has been manually edited"
  end
  
  def test_should_recognize_when_ancestor_name_changes
    root = Tax.new(:name => "bob's tax")
    child_1 = root.new_copy
    deny child_1.name_changed?, "child tax should not be name_changed? when root name is unchanged"
    root.name = BigDecimal("mary's tax")
    assert child_1.name_changed?, "child tax should be name_changed? when root name is different"
    child_1.name = BigDecimal("mary's tax")
    deny child_1.name_changed?, "child tax should not be name_changed? when root name is not different"
  end
  
  def test_should_auto_enable_tax_based_on_name_and_rate
    t = Tax.new
    assert t.enabled, "by default a new tax is enabled"
    t.auto_enable
    deny t.enabled, "after calling auto_enable when name and rate are blank, tax should not be enabled"
    t.rate = BigDecimal("0.0")
    t.auto_enable
    deny t.enabled, "after calling auto_enable when name is blank and rate is 0, tax should not be enabled"
    t.name = "bob"
    t.auto_enable
    assert t.enabled, "after calling auto_enable when name is set and rate is 0, tax should be enabled"
  end

  def test_should_return_changed_attributes
    root = Tax.new(:rate => BigDecimal("4.1"), :name => 'bob')
    child_1 = root.new_copy
    assert child_1.changed_attributes.empty?, "if nothing has changed, changed_attributes should be empty"
    root.name = "mary"
    assert child_1.changed_attributes.empty?, "if child has not been edited, changed_attributes should be empty"
    root.rate = "6"
    assert child_1.changed_attributes.empty?, "if child has not been edited, changed_attributes should be empty"
    
    child_1.edited = true
    assert_equal "bob", child_1.changed_attributes[:name], "if child has been edited and name is different from root.name, changed_attributes should contain name"
    assert_equal BigDecimal("4.1"), child_1.changed_attributes[:rate], "if child has been edited and rate is different from root.rate, changed_attributes should contain rate"
    
    root_2 = Tax.new(:rate => BigDecimal("4.1"), :name => 'bob')
    child_2 = root_2.new_copy
    child_2.name = "mary"
    assert_equal "mary", child_2.changed_attributes[:name], "if child has been edited and name is different from root.name, changed_attributes should contain name"
    assert_nil child_2.changed_attributes[:rate], "if child has been edited but rate is same as root.rate, changed_attributes should NOT contain rate"
    
    
  end
  

  
end
