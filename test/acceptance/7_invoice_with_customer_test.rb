$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'


# Test cases for User Story 7
# User can Invoice with Customer information
class InvoiceWithCustomer < SageAccepTestCase
  fixtures :users
  fixtures :customers
  fixtures :invoices
  fixtures :contacts
  include AcceptanceTestSession
  
  def setup
    @basic_user = watir_session.with(:basic_user)
    @basic_user.logs_in  
  end
  
  def teardown
    @basic_user.teardown 
  end
  
  # 2- User can invoice with a new customer added on the fly
  def test_invoice_with_new_customer

    @basic_user.goto_new_invoice_site_url
    
    puts users(:basic_user).profile.company_country
    
    #Enter an new Customer
    @basic_user.click_new_customer_button()
    
    #enter the country first

    @basic_user.enter_customer_data(
              :country => "Canada")
    
    
    @basic_user.enter_customer_data(
        :name => "Test 7 Customer",
        :address1 => "New Address1", 
        :address2 => "New Address2", 
        :city => "New City", 
        :province_state => "Saskatchewan",
        :postalcode_zip => "S7S 7S7",
        :website => "New Website", 
        :phone => "New Phone", 
        :fax => "New Fax"        
    )
    
    # check that customer gets added
    assert_difference( 'Customer.find(:all).size', 1) do    
      @basic_user.click_customer_add_button
    end
    
    #back on invoice page
    assert_equal "Invoices: new", @basic_user.title 
    
    @basic_user.wait()
    # Compare before and after creating invoice
    assert_difference( 'Invoice.find(:all).size', 1) do
         @basic_user.button(:value, "Save Invoice").click
    end
    
    #back on invoice page
    
    c = Customer.find_by_name('Test 7 Customer')
    
    verify_customer_data_fields(
        c,
        :name => "Test 7 Customer", 
        :address1 => "New Address1", 
        :address2 => "New Address2", 
        :city => "New City", 
        :postalcode_zip => "S7S 7S7",              
        :province_state => "Saskatchewan",
        :country => "CA",
        :website => "New Website", 
        :phone => "New Phone", 
        :fax => "New Fax" )
  end
  
  # 3- User gets an error when adding a new customer on the fly in invoice
  def test_invoice_with_new_customer_with_error
    @basic_user.user.profile.company_country = nil
    @basic_user.user.save(false)
    
    @basic_user.wait()
    @basic_user.goto_new_invoice_site_url
    @basic_user.wait()

    #Enter an existing Customer
    @customer = customers(:customer_with_contacts)
    
    #Enter an new Customer
    @basic_user.click_new_customer_button
    
    #enter the country first
    
    @basic_user.enter_customer_data(
                :country => "Canada")
    
    @basic_user.enter_customer_data(
        :name => @customer.name,
        :address1 => "New Address1", 
        :address2 => "New Address2", 
        :city => "New City", 
        :province_state => "Saskatchewan",
        :postalcode_zip => "S7S 7S7",
        :website => "New Website", 
        :phone => "New Phone", 
        :fax => "New Fax"        
    )

    # check that no customer gets added
    assert_no_difference( 'Customer.find(:all).size') do  
      @basic_user.click_customer_add_button(1)      
    end
    
    @basic_user.wait()
    
    # error message displayed 
    assert_not_equal 0, @basic_user.div(:id, "errorExplanation").text.length     
    
  end

  def test_customer_province_switch_ajax
    @basic_user.goto_new_invoice_site_url
    @basic_user.wait
    @basic_user.button(:id, "new-btn").click
    @basic_user.expects_ajax(2) do
      @basic_user.select_list(:id, "customer_country").select('United States')
    end
    
    assert @basic_user.element_by_xpath("id('customer_province_state')").html.include?("Select")

    @basic_user.expects_ajax(2) do
      @basic_user.select_list(:id, "customer_country").select('Andorra')
    end
    deny @basic_user.element_by_xpath("id('customer_province_state')").html.include?("Select")
  end
  
  def test_customer_province_switch_no_ajax
    @basic_user.goto_new_customer_url
    @basic_user.wait
    @basic_user.expects_ajax(2) do
      @basic_user.select_list(:id, "customer_country").select('United States')
    end
    
    # assert @basic_user.select_list(:id, "customer_province_state").html.include?("Select")
    # 
    # @basic_user.expects_ajax(2) do
    #   @basic_user.select_list(:id, "customer_country").select('Andorra')
    # end
    # deny @basic_user.select_list(:id, "customer_province_state").html.include?("Select")
  end
  
  def verify_customer_data_fields(c, fields)   
    fields.each_pair do |field, value|
      assert_equal(value, c.send(field))          
    end
  end  
  
end
