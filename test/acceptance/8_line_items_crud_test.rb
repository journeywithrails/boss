$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

#test cases for user login
class LineItemsCrud8Test < SageAccepTestCase
#  include Watir
  include AcceptanceTestSession
  fixtures :users, :invoices, :line_items
  
  def setup
    @basic_user = watir_session.with(:basic_user)
    @basic_user.logs_in    
  end
  
  def teardown 
    @basic_user.teardown
  end


 #Create two line items, then delete one and post.
  def test_should_create_and_delete_line_items_before_post
    assert_difference 'Invoice.count' do
      assert_difference 'LineItem.count', 1 do
        @basic_user.creates_new_invoice
        @basic_user.enter_new_customer(
          :name => "Test 8 Customer Name 4")        
        
        #get first row in the table.
        trows = @basic_user.line_items_rows
        assert_equal 1, trows.length
        tr1 = trows[::WatirBrowser.item_index(1)]
        assert tr1.exists?
        @basic_user.populate(tr1.text_field(:name, "invoice[line_items_attributes][][description]"), "Description one")

        @basic_user.link(:id, "add_line_item").click

        #get second row in the table.
        trows = @basic_user.line_items_rows
        assert_equal 2, trows.length
        tr2 = trows[::WatirBrowser.item_index(2)]
        assert tr2.exists?

        @basic_user.populate(tr2.text_field(:name, 'invoice[line_items_attributes][][description]'),'Description two')

        #remove the first line item
        @basic_user.line_items_rows[::WatirBrowser.item_index(1)].link(:name, 'remove').click

        @basic_user.submits
      end
    end

   invoice = Invoice.find(:first, :order => 'id desc')
   assert_equal 1, invoice.line_items.count
   assert_equal 'Description two', invoice.line_items[0].description
  end
 
  # Test editing an invoice with line items
 
  #Remove first line item from existing invoice
  def test_should_remove_first_line_item_from_invoice
    assert_no_difference 'Invoice.count' do
      assert_difference 'LineItem.count', -1 do
        @basic_user.edits_invoice(invoices(:invoice_with_line_items).id)
        
        #get first row in the table.
        trows = @basic_user.line_items_rows
        assert_equal 2, trows.length
        tr1 = trows[::WatirBrowser.item_index(1)]
        assert tr1.exists?
        @basic_user.populate(tr1.text_field(:name, "invoice[line_items_attributes][][description]"),"Removed Description one")

        #remove the first line item
        tr1.link(:name, 'remove').click

        @basic_user.submits
      end
    end
    
   invoice = Invoice.find(invoices(:invoice_with_line_items).id)
   assert_equal 1, invoice.line_items.count
   assert_equal line_items(:line_item_two).description, invoice.line_items[0].description
  end

  #Remove second line item from existing invoice
  def test_should_remove_second_line_item_from_invoice
    assert_no_difference 'Invoice.count' do
      assert_difference 'LineItem.count', -1 do
        @basic_user.edits_invoice(invoices(:invoice_with_line_items).id)
        
        #get first row in the table.
        trows = @basic_user.line_items_rows
        assert_equal 2, trows.length
        tr2 = trows[::WatirBrowser.item_index(2)]
        assert tr2.exists?
        @basic_user.populate(tr2.text_field(:name, "invoice[line_items_attributes][][description]"),"Removed Description two")

        #remove the second line item
        tr2.link(:name, 'remove').click

        @basic_user.submits
      end
    end
    
   invoice = Invoice.find(invoices(:invoice_with_line_items).id)
   assert_equal 1, invoice.line_items.count
   assert_equal line_items(:line_item_one).description, invoice.line_items[0].description    
    
  end
 
 
  #Add and remove items from existing invoice
  def test_should_add_edit_and_remove_line_items_in_invoice
    assert_no_difference 'Invoice.count' do
      assert_no_difference 'LineItem.count' do
        @basic_user.edits_invoice(invoices(:invoice_with_line_items).id)
        
        @basic_user.link(:id, "add_line_item").click

        #get newly added last row in the table to enter text
        trows = @basic_user.line_items_rows
        assert_equal 3, trows.length
        tr = trows[::WatirBrowser.item_index(trows.length)]
        assert tr.exists?
        @basic_user.populate(tr.text_field(:name, "invoice[line_items_attributes][][description]"),'Description of new line item')
        
        #remove the second line item
        trows = @basic_user.line_items_rows
        assert_equal 3, trows.length
        tr = trows[::WatirBrowser.item_index(2)]
        assert tr.exists?
        @basic_user.populate(tr.text_field(:name, "invoice[line_items_attributes][][description]"),"Deleted Description two")
        tr.link(:name, 'remove').click
        assert_equal false, tr.visible?
        
        #edit the first row in the table.
        trows = @basic_user.line_items_rows
        assert_equal 3, trows.length
        tr = trows[::WatirBrowser.item_index(1)]
        assert tr.exists?
        @basic_user.populate(tr.text_field(:name, "invoice[line_items_attributes][][description]"),"Changed Description One")

        @basic_user.submits
      end
    end
    
   invoice = Invoice.find(invoices(:invoice_with_line_items).id)
   assert_equal 2, invoice.line_items.count
   
   assert_equal 'Changed Description One', invoice.line_items[0].description
   assert_equal line_items(:line_item_one).description, invoice.line_items[0].description
  end

  # DSL tests

  #Test dsl for add, remove, and edit items from existing invoice
  def test_dsl_should_add_edit_and_remove_line_items_in_invoice
    assert_no_difference 'Invoice.count' do
      assert_no_difference 'LineItem.count' do
        @basic_user.edits_invoice(invoices(:invoice_with_line_items).id)
        assert_equal 3, @basic_user.adds_line_item(:unit => 'New line item', :description => 'Description of new line item')
        assert @basic_user.removes_line_item(2)
        @basic_user.edits_line_item(1, :description => 'Changed Description One').
         and_submits
      end
    end
    
    invoice = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal 2, invoice.line_items.count

    assert_equal 'Changed Description One', invoice.line_items[0].description
    assert_equal line_items(:line_item_one).description, invoice.line_items[0].description
  end

  
end
