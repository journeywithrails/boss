require File.dirname(__FILE__) + '/../test_helper'

class BookkeeperTest < ActiveSupport::TestCase
  fixtures :users, :bookkeepers, :billers, :bookkeeping_contracts, :roles
  include Sage::BusinessLogic::Exception

  def test_should_keep_books_for_biller
    bk_user = users(:bookkeeper_user)
    bi_user = users(:wants_bookkeeper_user)
    bk = bk_user.bookkeeper
    bi = bi_user.biller
    
    # assert that we can tell the difference between user and role by id.
    assert_not_equal bk.id, bk_user.id, "bookkeeper.id and bookkeeper.user.id should not be the same for this test."
    assert_not_equal bi.id, bi_user.id, "biller.id and biller.user.id should not be the same for this test."
    
    # regular case
    assert_difference 'BookkeepingContract.count', 1, 'bookkeeping_contract should be created' do
      bk.keep_books_for!(bi)
    end
    assert bk.user.has_role?('bookkeeping', bi.user)
    bkc = bk.bookkeeping_contracts.find_by_bookkeeping_client_id(bi)
    assert bkc, 'bookkeeping_contract should have correct values'
    assert_equal bi_user.biller, bkc.bookkeeping_client, 'bookkeeping_client should be in contract'
    assert_equal bk_user.bookkeeper, bkc.bookkeeper, 'bookkeeper should be in contract'

    #should not double-keep books for biller
    assert_no_difference 'BookkeepingContract.count' do
      bk.keep_books_for!(bi)
    end
  end
  
  
  def test_should_stop_keeping_books_for_biller
    # set up test case
    bk_user = users(:bookkeeper_user)
    bi_user = users(:wants_bookkeeper_user)
    bk = bk_user.bookkeeper
    bi = bi_user.biller

    bk.keep_books_for!(bi)
    assert bk.user.has_role?('bookkeeping', bi.user)
    assert bk.bookkeeping_contracts.find_by_bookkeeping_client_id(bi)
    
    # regular case
    assert_difference 'BookkeepingContract.count', -1 do
      bk.stop_keeping_books_for!(bi)
    end

    deny bk.user.has_role?('bookkeeping', bi.user)
    deny bk.bookkeeping_contracts.find_by_bookkeeping_client_id(bi)
    
    # should not double-stop keeping books for biller
    assert_no_difference 'BookkeepingContract.count' do
      assert_raise RolesException do
        bk.stop_keeping_books_for!(bi)
      end
    end
  end
  
  def test_should_raise_if_no_contract_when_stop_keeping_books
    # set up test case
    bk_user = users(:bookkeeper_user)
    bi_user = users(:wants_bookkeeper_user)
    bk = bk_user.bookkeeper
    bi = bi_user.biller
    
    User.any_instance.expects(:has_no_role).returns(true)    
    
    assert_no_difference 'BookkeepingContract.count' do
      assert_raise BookkeepingContractException do
        bk.stop_keeping_books_for!(bi)
      end
    end
    
    deny bk.user.has_role?('bookkeeping', bi.user)
    deny bk.bookkeeping_contracts.find_by_bookkeeping_client_id(bi)
    
  end  
  
  def test_should_raise_if_contract_cannot_be_created
    bk_user = users(:bookkeeper_user)
    bi_user = users(:wants_bookkeeper_user)
    bk = bk_user.bookkeeper
    bi = bi_user.biller

    bk.bookkeeping_contracts.expects(:create).returns(false)
    
    assert_raise BookkeepingContractException do
      bk.keep_books_for!(bi)
    end
  end

  def test_should_raise_if_role_cannot_be_added
    bk_user = users(:bookkeeper_user)
    bi_user = users(:wants_bookkeeper_user)
    bk = bk_user.bookkeeper
    bi = bi_user.biller

    User.any_instance.expects(:has_role).returns(false)
    
    assert_raise RolesException do
      bk.keep_books_for!(bi)
    end
    
  end
  
  def test_should_delegate_to_user_on_method_missing
    bk_user = users(:bookkeeper_user)
    bk = bk_user.bookkeeper
    
    User.any_instance.expects(:method_to_delegate).returns('delegated')
    assert_equal 'delegated', bk.method_to_delegate
  end

  def test_should_have_user
    bk = Bookkeeper.find(:first)
    assert bk.user
  end
  
end
