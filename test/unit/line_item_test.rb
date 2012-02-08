require File.dirname(__FILE__) + '/../test_helper'

class LineItemTest < Test::Unit::TestCase
  fixtures :line_items

  # Replace this with your real tests.
  def test_should_destroy_method
    l = LineItem.new
    assert !l.should_destroy?
    l.should_destroy = "1"
    assert l.should_destroy?    
  end
  
  def test_should_calculate_subtotal
    l = LineItem.new
    assert 0, l.subtotal
    
    l.quantity = "0"
    assert 0, l.subtotal

    l.price = "0"
    assert 0, l.subtotal
    
    l.quantity = "1.00"
    assert 0, l.subtotal

    l.price = "2.50"
    assert 2.5, l.subtotal
    
    l.quantity = ".70"
    assert 1.75, l.subtotal
  end
  
  def test_should_reject_over_a_million
    l = LineItem.new
    l.quantity = 8
    l.price = BigDecimal.new("125000")
    assert_not_valid l
    l.price = BigDecimal.new("124999")
    assert_valid l
  end
  
  
end
