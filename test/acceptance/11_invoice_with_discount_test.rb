$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 11
# Users can invoice with discount
class InvoiceWithDiscount < SageAccepTestCase
  
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers
  
  def setup
    @user = watir_session.with(:user_without_profile)
    @user.logs_in
    @number_of_line_items = 5
  end
  
  def teardown
    @user.teardown
  end

  
  # 1- Users can enter a discount per invoice. Discount is entered before tax
  def test_discount_per_invoice


#    puts "Customer.find_by_name('heavy_user_customer_1'): #{Customer.find_by_name('heavy_user_customer_1').inspect}"

    # Add an Invoice
    assert_difference 'Invoice.count' do
      #Create new Invoice and fill it up
      @user.creates_new_invoice
      fill_invoice_for @user 
      
      #Customer Info    
      current_customer = customers("heavy_user_customer_1".to_sym)
      @user.enter_new_customer(:name => current_customer.name)    
                  
      # quantity and price keep the same value so calculating subtotal is easy            
      quantity = 10 
      price = 5.00
      discount = 50.00
      discount_percent = 10.00
      	  
      #Add line items
      add_line_items(quantity, price)
	  
      # Discount and Type
      @user.populate(@user.text_field(:id, "invoice_discount_value"),discount.to_s)
      @user.select_list(:id, "invoice_discount_type").option(:text, "amount").select
      
      # Submit and verify           
      assert_difference 'LineItem.count', @number_of_line_items do
        @user.submits        
      end
      
      # Edit Invoice
      id_last_invoice = Invoice.find(:first, :order => "id DESC").id
      @user.edits_invoice(id_last_invoice)
      
      # Verify SubTotal, Discount and Total 
      subTotal = quantity * price * @number_of_line_items
      total = subTotal - discount
      
      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)
      
      # Changing discount type
      @user.expects_ajax(2) do
        @user.populate(@user.text_field(:name, 'invoice[discount_value]'), discount_percent.to_s)
        @user.select_list(:name, 'invoice[discount_type]').select "percent"
      end

      @user.submits

      # Edit Invoice
      id_last_invoice = Invoice.find(:first, :order => "id DESC").id
      @user.edits_invoice(id_last_invoice)
      
      # Verify SubTotal, Discount and Total 
      discount = discount_percent * subTotal / 100.00
      total = subTotal - discount
      
      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)
      
    end        
  end
  
  def add_line_items(quantity, price)
      # Add line items
      (1..@number_of_line_items).each do | i |
        if i == 1 
           @user.edits_line_item(i, 
            :unit => "Item A" + i.to_s,
            :description => "Description for Item A" + i.to_s,
            :quantity => quantity.to_s,
            :price => price.to_s)
        else
          assert_equal i, @user.adds_line_item(
            :unit => "Item A" + i.to_s,
            :description => "Description for Item A" + i.to_s,
            :quantity => quantity.to_s,
            :price => price.to_s)
        end
     end
  end
  
  # 2- Users can invoice with no discount
  def test_invoice_no_discount

    # Add an Invoice
    assert_difference 'Invoice.count' do
      
      #Create new Invoice and fill it up
      @user.creates_new_invoice
      fill_invoice_for @user 

      #Customer Info    
      current_customer = customers("heavy_user_customer_1".to_sym)
      @user.enter_new_customer( 
        :name => current_customer.name
      )    
            
      # quantity and price initial values
      quantity = 20
      price = 4.00
      	  
      #Add line items
      add_line_items(quantity, price)
	        
      # Submit and verify
      assert_difference 'LineItem.count', @number_of_line_items do
        @user.submits        
      end                          
    end  
  end

  # 3A - Once the discount has been changed, the sub total, tax and grand total
  # are automatically updated
  # Case A: Check changes are updated before submitting
  def test_invoice_discount_changed_a
    # Add an Invoice
    assert_difference 'Invoice.count' do
      
      #Create new Invoice and fill it up
      @user.creates_new_invoice
      fill_invoice_for @user 
      
      #Customer Info    
      current_customer = customers("heavy_user_customer_1".to_sym)
      @user.enter_new_customer(
        :name => current_customer.name
      )    
                  
      # quantity and price keep the same value so calculating subtotal is easy            
      quantity = 10 
      price = 5.00
      discount = 50.00
      discount_percent = 10.00
      	  
      #Add line items
      add_line_items(quantity, price)
	        
      # Discount and Type

      @user.populate(@user.text_field(:id, "invoice_discount_value"), discount.to_s)
      @user.select_list(:id, "invoice_discount_type").option(:text, "amount").select

      @user.b.wait
      sleep 1
      # Verify SubTotal, Discount and Total 
      subTotal = quantity * price * @number_of_line_items
      total = subTotal - discount
      
      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)
	  
      # Changing discount type
	  @user.expects_ajax(2) do
	  	@user.populate(@user.text_field(:name, 'invoice[discount_value]'), discount_percent.to_s)
  		@user.select_list(:name, 'invoice[discount_type]').select "percent"
	  end

      # Verify SubTotal, Discount and Total 
      discount = discount_percent * subTotal / 100.00
      total = subTotal - discount
      
      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)
	  
	  # Changing discount and type and verify
	  # Change to 200 discount Amount
	  discount = 200.00
	  @user.expects_ajax(2) do
	  	@user.populate(@user.text_field(:name, 'invoice[discount_value]'), discount.to_s)
      @user.select_list(:name, 'invoice[discount_type]').select "amount"
	  end
	  
	  # Verify SubTotal, Discount and Total 
	  total = subTotal - discount

      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)

	  # Changing discount and type and verify
	  # Change to 100% discount
	  discount_percent = 100.00
	  @user.expects_ajax(2) do
	  	@user.populate(@user.text_field(:name, 'invoice[discount_value]'), discount_percent.to_s)
  		@user.select_list(:name, 'invoice[discount_type]').select "percent"
	  end
	  
	  # Verify SubTotal, Discount and Total 
	  discount = discount_percent * subTotal / 100.00
	  total = subTotal - discount

      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)

	  # Changing discount and type and verify
	  # Change to amount discount equal to subtotal so total is 0
	  @user.expects_ajax(2) do
	  	@user.populate(@user.text_field(:name, 'invoice[discount_value]'), subTotal.to_s)
      @user.select_list(:name, 'invoice[discount_type]').select "amount"
	  end

	  # Verify SubTotal, Discount and Total 
	  discount = subTotal
	  total = subTotal - discount

      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)

	  # Changing discount and type and verify
	  # Set discount amount to 0 without changing type
	  discount = 0.00
	  @user.expects_ajax(1) do
	  	@user.populate(@user.text_field(:name, 'invoice[discount_value]'), discount.to_s)
	  end

	  # Verify SubTotal, Discount and Total 
	  total = subTotal - discount

      assert_equal(format_amount(subTotal), @user.span(:id, "invoice_line_items_total").text)
      assert_equal(format_amount(discount), @user.span(:id, "invoice_discount_amount").text)
      assert_equal(format_amount(total), @user.span(:id, "invoice_total").text)
      
      # Submit and verify           
      assert_difference 'LineItem.count', @number_of_line_items do
        @user.submits        
      end
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

end