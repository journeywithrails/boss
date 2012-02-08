$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 25
# Add/Edit Customers

# Description: As a user, I want to add/edit a customer's information 
# so that I can keep my customer information up to date 
# and use my customer information when I invoice.

class CustomerAddEditTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :customers

  def setup
    @user = watir_session.with(:complete_user)
    @user.logs_in  
  end
  
  def teardown
    @user.teardown
  end
  
  # User acceptance tests 1 - 10, add mode
    # User can add the customer's group/name
    # User can add the customer's address1
    # User can add the customer's address2
    # User can add the customer's city
    # User can add the customer's state
    # User can add the customer's country
    # User can add the customer's postal code/zip
    # User can add the customer's website
    # User can add the customer's phone
    # User can add the customer's fax
  def test_add_customer
    
    # to to the new customer url directly
    # the other option was to click new from the customers page
    # Open the Customer list
    #@user.displays_customer_list
    #@user.link(:text => 'New').click
    #@user.b.wait()
    goto_new_customer_url
  
    @user.enter_customer_data(
              :country => "Canada")
  
    @user.enter_customer_data(
              :name => "New Customer Name", 
              :address1 => "New Address1", 
              :address2 => "New Address2", 
              :city => "New City", 
              :province_state => "Saskatchewan",
              :postalcode_zip => "S7S 7S7",
              :website => "New Website", 
              :phone => "New Phone", 
              :fax => "New Fax" )
    
    @user.submits    
    
    # verify create was successful
    assert_equal "Customers: edit", @user.title 

    c = Customer.find_by_name('New Customer Name')


    verify_customer_data_fields(
          c,
          :name => "New Customer Name", 
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
    
  def test_name_is_required
    
    goto_new_customer_url
  
    @user.enter_customer_data(
              :country => "Canada")
  
    @user.enter_customer_data(
              :address1 => "New Address1", 
              :address2 => "New Address2", 
              :city => "New City", 
              :province_state => "Saskatchewan",
              :postalcode_zip => "S7S 7S7",
              :website => "New Website", 
              :phone => "New Phone", 
              :fax => "New Fax" )
    
    @user.submits    
    
    # verify create was unsuccessful
    assert_equal "Customers: create", @user.title 

    # error message displayed 
    assert_not_equal 0, @user.div(:id, "errorExplanation").text.length     

    # look up customer by postal code and check that the record is not added
    c = Customer.find_by_postalcode_zip('S7S 7S7')
    assert_nil c
    
  end
  
  def test_name_cannot_be_duplicated
    
    goto_new_customer_url
  
    @user.enter_customer_data(
              :country => "Mexico")
  
    @user.enter_customer_data(
              :name => "customer with all address fields",
              :address1 => "Duplicate Name Address1", 
              :address2 => "Duplicate Name  Address2", 
              :city => "Duplicate Name City", 
              :province_state => "Sinaloa",
              :postalcode_zip => "M12345",
              :website => "Duplicate Name Website", 
              :phone => "Duplicate Name Phone", 
              :fax => "Duplicate Name Fax" )
    
    @user.submits    
    
    # verify create was unsuccessful
    assert_equal "Customers: create", @user.title 

    # error message displayed 
    assert_not_equal 0, @user.div(:id, "errorExplanation").text.length     

    # look up customer by postal code and check that the record is not added
    c = Customer.find_by_postalcode_zip('M12345')
    assert_nil c
    
  end
  
  # User acceptance tests 1 - 10, edit mode, excluding 5, 7:  
    # User can edit the customer's group/name
    # User can edit the customer's address1
    # User can edit the customer's address2
    # User can edit the customer's city
    # User can edit the customer's postal code/zip
    # User can edit the customer's website
    # User can edit the customer's phone
    # User can edit the customer's fax
  def test_edit_customer_text_fields

    # go directly to the customers/55/edit url
    # the other choice is to select a customer from the list but this is brittle
    goto_edit_customer_url  
    # Click Edit for the 4th customer in the list
    #edit_customer_in_list(4)

    @user.enter_customer_data(
              :name => "Modified Customer Name", 
              :address1 => "Modified Address1", 
              :address2 => "Modified Address2", 
              :city => "Modified City", 
              :postalcode_zip => "C4C 4C4",
              :website => "Modified Website", 
              :phone => "Modified Phone", 
              :fax => "Modified Fax" )
    
    @user.submits    
    
    # verify update was successful
    assert_equal "Customers: edit", @user.title 

    c = Customer.find(customers(:customer_with_all_address_fields).id)
    
    verify_customer_data_fields(
          c,
          :name => "Modified Customer Name", 
          :address1 => "Modified Address1", 
          :address2 => "Modified Address2", 
          :city => "Modified City", 
          :postalcode_zip => "C4C 4C4",
          :website => "Modified Website", 
          :phone => "Modified Phone", 
          :fax => "Modified Fax" )
  end
  
  # User acceptance test 7:  User can edit the customer's country
  # User acceptance test 5:  User can edit the customer's state  
  def test_edit_customer_country_and_state
  
    # Click Edit for the 4th customer in the list
    # edit_customer_in_list(4)
    goto_edit_customer_url
    # modify the country 
    @user.enter_customer_data(
      :country => "United States")
    @user.b.wait()  
    
    @user.enter_customer_data(
      :province_state => "New York")    
    
    @user.submits    
    @user.b.wait()
    
    # verify update was successful
    assert_equal "Customers: edit", @user.title    
    
    c = Customer.find(customers(:customer_with_all_address_fields).id)
    
    verify_customer_data_fields(
          c,
          :country => "US",
          :province_state => "New York")
    
    #@user.link(:text => 'Edit').click
    #@user.b.wait()

    # verify we are back on edit page
    assert_equal "Customers: edit", @user.title

    # Verify changes to customer 4
    verify_customer_view_fields(
            :country => "US",
            :province_state => "New York")            

  end
  
  # User acceptance test 7:  User can edit the customer's country
  # when the customer country is modified, 
  # the postal code and province labels should update
  def test_edit_customer_country_and_check_labels
  
    goto_edit_customer_url
    # modify the country 
    @user.enter_customer_data(
      :country => "United States")
    @user.b.wait()            
    
    # check that state and postal label are displayed 
    verify_customer_labels(
            :postalcode_label => "Zip Code:",
            :province_state_label => "State:")   
            
    # modify the country to Australia and check the labels
    @user.enter_customer_data(
      :country => "Australia")
    @user.b.wait()            
    
    # check that state and postal label are displayed 
    verify_customer_labels(
            :postalcode_label => "Postal Code:",
            :province_state_label => "Province:")   
    
    @user.submits    
    
    # verify update was successful
    assert_equal "Customers: edit", @user.title    

  end
    
  # helper methods  
  
  def goto_new_customer_url
    @user.goto_new_customer_url
  end
  
  def goto_edit_customer_url
    c = customers(:customer_with_all_address_fields)
    @user.goto(@user.edit_customer_url(c.id))
  end
  
  # obsolete routine
  #def edit_customer_in_list(index)
  #  trows = @user.b.entity_list_rows
  #  tr = trows[index]
  #
  #  assert tr.exists? && tr.visible?, 'tried to edit a non-existent line_item.'
  #  tr.link(:text, 'Edit').click
  #  @user.b.wait()
  #  
    # verify we are on edit page
  #  assert_equal "Customers: edit", @user.title
  #  self    
  #end
    
  #def enter_customer_data(fields)
  #  fields.each_pair do |field, value|
  #  
  #    case field.to_s
  #    # country is a  select
  #    when 'country' then
  #      @user.expects_ajax(1) do
  #        @user.select_list(:id, "customer_#{field.to_s}").select(value)          
  #      end
  #    when 'province_state' then
  #      # province_state is a select for known countries 
  #      # and a textbox for unknown countries
  #      
  #      # the type of a textbox is 'type', select is select-one
  #      case @user.select_list(:id, "customer_#{field.to_s}").type
  #      when "text" then
  #        @user.text_field(:id, "customer_#{field.to_s}").set(value)
  #      when "select-one" then
  #        @user.select_list(:id, "customer_#{field.to_s}").select(value)
  #      end
  #      
  #    else
  #      @user.text_field(:id, "customer_#{field.to_s}").set(value)
  #    end
  #  end
  #
  # end
  
  def verify_customer_view_fields(fields)   
    fields.each_pair do |field, value|
      # country is a selects
      case field.to_s 
      when 'country' then
        assert_equal(value, @user.select_list(:id, "customer_#{field.to_s}").value)          
      when 'province_state' then
        # province_state is a select for known countries 
        # and a textbox for unknown countries
        # the type of a textbox is 'type', select is select-one
        case @user.select_list(:id, "customer_#{field.to_s}").type
        when "text" then
          assert_equal(value, @user.text_field(:id, "customer_#{field.to_s}").text)          
        when "select-one" then
          assert_equal(value, @user.select_list(:id, "customer_#{field.to_s}").value)          
        end
      else
        assert_equal(value, @user.text_field(:id, "customer_#{field.to_s}").text)
      end    
    end
  end
  
  def verify_customer_data_fields(c, fields)   
    fields.each_pair do |field, value|
      assert_equal(value, c.send(field))          
    end
  end  
  
  def verify_customer_labels(fields)   
    # labels are in divs and do not have the customer prefix 
    # since the postal code and province partials are shared
    fields.each_pair do |field, value|
      assert_equal(value, @user.div(:id, "#{field.to_s}").text)
    end    
  end
    
end
