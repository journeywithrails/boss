require File.dirname(__FILE__) + '/../test_helper'

class SpsubscriptionTest < ActiveSupport::TestCase
  
  def setup
    @spaccount = Spaccount.find("InactiveSPAccountName")
  end
  
  def test_find_by_friendly_id
    spsubscription = @spaccount.spsubscriptions.find("Product1")
    assert_not_nil spsubscription
    assert_equal "Product1", spsubscription.service_code, "Product1 should be the product_code of the spsubscription found by friendly id"
  end
  
  def test_find_by_id
    spsubscription = @spaccount.spsubscriptions.find(1)
    assert_not_nil spsubscription
    assert_equal "Product1", spsubscription.service_code, "Product1 should be the product_code of the spsubscription found by friendly id"
  end
  
  def test_find_first_by_spaccount_id
    spsubscription = [@spaccount.spsubscriptions.find(:first, :conditions => {:service_code => 'Product2'})].flatten
    assert_equal 1, spsubscription.size, "There should be 1 elements when find by first"    
    assert_equal "Product2", spsubscription[0].service_code, "Product2 should be the product_code of the spsubscription found first"
  end
  
  def test_find_all
    spsubscriptions = [@spaccount.spsubscriptions].flatten
    assert_not_nil spsubscriptions
    assert_equal 2, spsubscriptions.size, "There should be 2 elements when finding spsubscriptions for the first spaccounts"    
  end
  
  def test_add_duplicate_subscription
    spsubscription = create_new_subscription(:service_code => 'Product1')
    assert_no_difference('Spsubscription.count') do
      spsubscription.save
    end
    assert_equal 1, spsubscription.errors.size, "The errors array should have 1 message after adding duplicate spsubscription product code"
  end

  def test_duplicate_transaction_id
    spsubscription = create_new_subscription(:transaction_id => 1)
    spsubscription.save
    assert_equal 1, spsubscription.errors.size, "The errors array should have one error when adding with a duplicate transaction id"
  end

  def test_new_subscription_should_validate_service_code
    spsubscription = create_new_subscription(:service_code => 'invalid')
    spsubscription.save
    assert_equal 1, spsubscription.errors.size, "The errors array should have one error when adding with an invalid service code"
  end
  
  def test_new_subscription_should_validate_quantity
    spsubscription = create_new_subscription(:qty => -1)
    spsubscription.save
    assert_equal 1, spsubscription.errors.size, "The errors array should have one error when adding with an invalid quantity"
  end
  
  def test_should_create_subscription_with_active_user
    @spaccount = Spaccount.find("WithoutSubscriptionSPAccountName")
    spsubscription = create_new_subscription(:qty => 1)
    assert_difference('Spsubscription.count', 1) do
      assert spsubscription.save
    end
    
    spsubscription.reload
    assert_equal 1, spsubscription.qty
    assert_equal true, spsubscription.spaccount.user.active, 'User should be active after subscription with new_qty=>1 is created.'
  end
  
  def test_should_create_subscription_with_inactive_user
    @spaccount = Spaccount.find("WithoutSubscriptionSPAccountName")
    spsubscription = create_new_subscription(:qty => 0)
    assert_difference('Spsubscription.count', 1) do
      spsubscription.save
    end

    spsubscription.reload
    assert_equal 0, spsubscription.qty
    assert_equal false, spsubscription.spaccount.user.active, 'User should be active after subscription with new_qty=>0 is created.'
  end
  
  private
    def create_new_subscription(params={})
      params[:transaction_id] ||= UUIDTools::UUID.timestamp_create().to_s
      params[:service_code] ||= 'BB-01'
      params[:qty] ||= 1
      @spaccount.spsubscriptions.new(params)
    end
  
end
