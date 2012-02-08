require File.dirname(__FILE__) + '/../test_helper'

class BillerTest < ActiveSupport::TestCase
  fixtures :billers, :users, :bookkeepers, :bookkeeping_contracts
  
  def test_biller_has_bookkeeper_contract
    bi = billers(:biller_has_bookkeeping_contract)
    assert_equal 1, bi.bookkeeping_contracts.count
    bk = bi.bookkeepers.first
    assert users(:bookkeeper_user).sage_username, bk.user.sage_username

    bi = billers(:doesnt_want_bookkeeper_biller)
    assert_equal 0, bi.bookkeeping_contracts.count
  end
  
  # ensure biller doesn't break when refactoring methods from user.
  def test_biller_has_biller_methods
    bi = billers(:basic_biller)
    bi.generate_next_auto_number
  end

  def test_biller_has_user
    bi = billers(:basic_biller)
    assert bi.user
  end
  
  def test_total_invoice_amounts
    bi = billers(:basic_biller)
    assert_equal 141.11, bi.total_invoice_amounts.to_f
  end
  
  def test_total_amount_owing
    bi = billers(:basic_biller)
    assert_equal 41.11, bi.total_amount_owing.to_f
  end
  
end
