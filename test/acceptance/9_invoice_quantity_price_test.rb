$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 9
# Users can Invoice with Quantity and Price
class InvoiceQuantityPrice < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers
  
  def setup
    @a_user = watir_session.with(:user_without_profile)
    @a_user.logs_in
    @number_of_line_items = 5.00
  end
  
  def teardown
    $log_on = false
    $log_concurrency = false
    @a_user.teardown
  end

    # 4- Test edge cases
  def test_invoice_with_quantity_and_price_changed_edge_cases
    # Add an Invoice
    assert_difference 'Invoice.count' do
      
    #Create new Invoice and fill it up
      @a_user.creates_new_invoice
      fill_invoice_for @a_user
      
      #Customer Info    
      current_customer = customers("heavy_user_customer_1".to_sym)
      @a_user.enter_new_customer( 
          :name => current_customer.name
      )    
      
      # quantity and price keep the same value so calculating subtotal is easy    
      quantity = 20
      price = 4.00
      discount = 50.00
      discount_percent = 10.00

      # Add line items
      add_line_items(quantity, price)
            
      # Discount and Type
      @a_user.text_field(:id, "invoice_discount_value").set(discount.to_s)
      @a_user.select_list(:id, "invoice_discount_type").option(:text, "amount").select
            
      # Submit and verify
      assert_difference 'LineItem.count', @number_of_line_items do
        @a_user.submits        
      end

      # Edit Invoice
      id_last_invoice = Invoice.find(:first, :order => "id DESC").id
      @a_user.edits_invoice(id_last_invoice)
	  
	  # Changing first line Quantity to Zero
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(1, :quantity => (0.00).to_s)
      end
	  
	  #Verifying quantity changed, line total and subtotal, discount and total
      assert_equal((0.00).to_s, @a_user.gets_line_item_at(1, :quantity))

	  assert_equal(format_amount(0.00).to_s, @a_user.gets_line_item_at(1, :subtotal)) 
	  
      subTotal = quantity * price * (@number_of_line_items-1)
      assert_equal(format_amount(subTotal).to_s, @a_user.span(:id, "invoice_line_items_total").text)

      assert_equal(format_amount(discount).to_s, @a_user.span(:id, "invoice_discount_amount").text)
	  
      assert_equal(format_amount(subTotal - discount).to_s, @a_user.span(:id, "invoice_total").text)
	  
	  	  
	  # Changing last line Price to Zero
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(@number_of_line_items, :price => (0.00).to_s)
      end

	  #Verifying quantity changed, line total and subtotal, discount and total
      assert_equal((0.00).to_s, @a_user.gets_line_item_at(@number_of_line_items, :price))

	  assert_equal(format_amount(0.00).to_s, @a_user.gets_line_item_at(@number_of_line_items, :subtotal))
	  
      subTotal = quantity * price * (@number_of_line_items-2)
      assert_equal(format_amount(subTotal).to_s, @a_user.span(:id, "invoice_line_items_total").text)

      assert_equal(format_amount(discount).to_s, @a_user.span(:id, "invoice_discount_amount").text)
	  
      assert_equal(format_amount(subTotal - discount).to_s, @a_user.span(:id, "invoice_total").text)
	  
	  # Changing first line Quantity to Negative value
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(1, :quantity => (-20.00).to_s)
      end
	  
	  # Changing last line Price to Negative value
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(@number_of_line_items, :price => (-4.00).to_s)
      end

	  #Verifying quantity changed, line total and subtotal, discount and total
      assert_equal((-20.00).to_s, @a_user.gets_line_item_at(1, :quantity))
      assert_equal((-4.00).to_s, @a_user.gets_line_item_at(@number_of_line_items, :price))

	  assert_equal(format_amount(-quantity*price).to_s, @a_user.gets_line_item_at(1, :subtotal))

	  assert_equal(format_amount(quantity * (-price)).to_s, @a_user.gets_line_item_at(@number_of_line_items, :subtotal))	 
	  
      subTotal = quantity * price * (@number_of_line_items-2) - (quantity * price * 2)
      assert_equal(format_amount(subTotal).to_s, @a_user.span(:id, "invoice_line_items_total").text)

      assert_equal(format_amount(discount).to_s, @a_user.span(:id, "invoice_discount_amount").text)
	  
      assert_equal(format_amount(subTotal - discount).to_s, @a_user.span(:id, "invoice_total").text)
	  
	  # Changing first line Quantity to a big value
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(1, :quantity => (1000000).to_s)
      end
	  
	  # Changing last line Price to a big value	  
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(@number_of_line_items, :price => (1000000.00).to_s)
      end

	  #Verifying quantity changed, line total and subtotal, discount and total
      assert_equal((1000000).to_s, @a_user.gets_line_item_at(1, :quantity))
      assert_equal((1000000.00).to_s, @a_user.gets_line_item_at(@number_of_line_items, :price))

	  assert_equal(format_amount(1000000 * price).to_s, format_amount(@a_user.gets_line_item_at(1, :subtotal)))

	  assert_equal(format_amount(quantity * 1000000.00).to_s, @a_user.gets_line_item_at(@number_of_line_items, :subtotal))  
	  
      subTotal = quantity * price * (@number_of_line_items-2) + (1000000 * price) + (quantity * 1000000.00)
      assert_equal(format_amount(subTotal).to_s, @a_user.span(:id, "invoice_line_items_total").text)

      assert_equal(format_amount(discount).to_s, @a_user.span(:id, "invoice_discount_amount").text)
	  
      assert_equal(format_amount(subTotal - discount).to_s, @a_user.span(:id, "invoice_total").text)
	  
	  # Changing first line Quantity to a small value
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(1, :quantity => (0.0001).to_s)
      end
	  
	  # Changing last line Price to a small value
      @a_user.expects_ajax(1) do
      	@a_user.edits_line_item(@number_of_line_items, :price => (0.0001).to_s)
      end

	  #Verifying quantity changed, line total and subtotal, discount and total
      assert_equal((0.0001).to_s, @a_user.gets_line_item_at(1, :quantity))
      assert_equal((0.0001).to_s, @a_user.gets_line_item_at(@number_of_line_items, :price))

	  assert_equal(format_amount(0.0001 * price).to_s, @a_user.gets_line_item_at(1, :subtotal)) 

	  assert_equal(format_amount(quantity * 0.0001).to_s, @a_user.gets_line_item_at(@number_of_line_items, :subtotal)) #5th cell	 
	  
      subTotal = quantity * price * (@number_of_line_items-2) + (0.0001 * price) + (quantity * 0.0001)
      assert_equal(format_amount(subTotal).to_s, @a_user.span(:id, "invoice_line_items_total").text)

      assert_equal(format_amount(discount).to_s, @a_user.span(:id, "invoice_discount_amount").text)
	  
      assert_equal(format_amount(subTotal - discount).to_s, @a_user.span(:id, "invoice_total").text)
	  
  	end
  end
  
  private
  def fill_invoice_for user
  
    # Invoice Info
    user.sets_invoice_info(
      :unique => "Inv-0001",
      :date => "2007-12-15",
      :reference => "Ref-0001",
      :description => "Original description for this Invoice"
    )
    
    # Contact Info
    #user.sets_invoice_contact(
    #    :first_name => "My Contact First Name",
    #    :last_name => "My Contact Last Name",
    #    :email => "abc@address.com"
    #)
    

  end

  def add_line_items(quantity, price)
	      # Add line items
	      (1..@number_of_line_items).each do | i |
	        if i == 1
	           @a_user.edits_line_item(i,
	            :unit => "Item A" + i.to_s,
	            :description => "Description for Item A" + i.to_s,
	            :quantity => quantity.to_s,
	            :price => price.to_s)
	        else
	          assert_equal i, @a_user.adds_line_item(
	            :unit => "Item A" + i.to_s,
	            :description => "Description for Item A" + i.to_s,
	            :quantity => quantity.to_s,
	            :price => price.to_s)
	        end
	     end
	  end
end