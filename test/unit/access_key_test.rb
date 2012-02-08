require File.dirname(__FILE__) + '/../test_helper'

class AccessKeyTest < Test::Unit::TestCase
#  fixtures :contacts
  fixtures :invoices
  
  def test_should_toggle_access
    ak = AccessKey.new(:valid_until => nil, :uses => 2)
    ak.keyable = invoices(:invoice_with_no_customer)
    ak.save!
    
    ak.toggle_uses!
    assert_equal 0, ak.uses
    ak.toggle_uses!
    assert_equal 99999, ak.uses
  end
  
  def test_use_succeeds_only_for_number_of_uses
    ak = AccessKey.new(:valid_until => nil, :uses => 2)
    ak.keyable = invoices(:invoice_with_no_customer)
    ak.save!
    assert ak.use?
    assert ak.use?
    assert !ak.use?
  end
  
  def test_use_succeeds_only_for_valid_date
    ak = AccessKey.new(:valid_until => 1.day.ago)
    ak.keyable = invoices(:invoice_with_no_customer)
    ak.save!
    assert !ak.use?

    ak = AccessKey.new(:valid_until => 1.day.from_now)
    ak.keyable = invoices(:invoice_with_no_customer)
    ak.save!
    assert ak.use?
  end
  
  def test_get_or_create_access_key_with_options
    keyable = invoices(:invoice_with_no_customer)
    assert_empty keyable.access_keys
    key = keyable.get_or_create_access_key
    assert_not_nil key
    deny_empty keyable.access_keys
    assert_equal 1, keyable.access_keys.length
    
    valid_date = 1.day.from_now
    key = keyable.get_or_create_access_key(:valid_until => valid_date)
    assert_equal 2, keyable.access_keys.length
    assert_not_nil key

    key = keyable.get_or_create_access_key(:valid_until => valid_date)
    assert_equal 2, keyable.access_keys.length
    assert_not_nil key

    key = keyable.get_or_create_access_key
    assert_not_nil key
    assert_equal 2, keyable.access_keys.length

  end
  
end
