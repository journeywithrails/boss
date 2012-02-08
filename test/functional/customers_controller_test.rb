require File.dirname(__FILE__) + '/../test_helper'
require 'customers_controller'

# Re-raise errors caught by the controller.
class CustomersController; def rescue_action(e) raise e end; end

class CustomersControllerTest < Test::Unit::TestCase
  include Arts
  fixtures :customers, :contacts
  fixtures :users
  fixtures :invoices, :payments, :pay_applications
  
  uses_transaction :test_ajax_should_not_lose_primary_contact_after_new_customer_error,
        :test_should_not_lose_primary_contact_after_new_customer_error   

  def setup
    @controller = CustomersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :basic_user unless %w{test_requires_login}.include?(method_name)
    stub_cas_check_status
  end

  def teardown
    $log_on = false
  end
  
  def test_requires_login
    unstub_cas
    get :index
    assert_redirected_to_cas_login
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:customers)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_ajax_should_get_new
    xhr :get, :new
    assert_template "customers/_new_customer_dialog"
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
    assert @response.body.include?("customer=1")
  end
  
  def test_ajax_should_get_edit
    xhr :get, :edit, :id => 1
    assert_template "customers/_edit_customer_dialog"
  end
  
  def test_should_destroy_customer
    assert_difference('Customer.count', -1) do
      delete :destroy, :id => 1
    end
  end
  
  def test_should_redirect_after_destroy
    delete :destroy, :id => 1  
    assert_redirected_to '/customers/overview'
  end
  
  
  def test_should_update_all_customer_fields
    login_as :complete_user
    put :update, :id => 55, :customer => {
      :address1 => 'address1 mod', 
      :address2 => 'address2 mod', 
      :city => 'Seattle', 
      :postalcode_zip => '12345', 
      :province_state => 'Washington', 
      :country => 'United States', 
      :website => 'www.sagesoftware.com', 
      :phone => '555-555-1414', 
      :fax => '555-555-1616' }
    
    customer = assigns(:customer)
    assert_equal 'address1 mod', customer.address1, "customer address1 should be address1 mod"    
    assert_equal 'address2 mod', customer.address2, "customer address2 should be address2 mod"    
    assert_equal 'Seattle', customer.city, "customer city should be Seattle"
    assert_equal '12345', customer.postalcode_zip, "customer postalcode_zip should be 12345"
    assert_equal 'Washington', customer.province_state, "customer province_state should be Washington"
    assert_equal 'United States', customer.country, "customer country should be United States"
    assert_equal 'www.sagesoftware.com', customer.website, "customer website should be www.sagesoftware.com"
    assert_equal '555-555-1414', customer.phone, "customer phone should be 555-555-1414"
    assert_equal '555-555-1616', customer.fax, "customer fax should be 555-555-1616"    
    
  end
  
  def test_should_add_customer_with_all_fields
    
    assert_difference('Customer.count') do
      post :create, :customer => {
      :name => 'customer name',
      :address1 => 'address1 new', 
      :address2 => 'address2 new', 
      :city => 'Calgary', 
      :postalcode_zip => 'V5V 5V5', 
      :province_state => 'Alberta', 
      :country => 'Canada', 
      :website => 'www.sage.com', 
      :phone => '555-555-1717', 
      :fax => '555-555-1818' }
    end
    
    customer = assigns(:customer)
    assert_equal 'customer name', customer.name, "customer address1 should be address1 new"        
    assert_equal 'address1 new', customer.address1, "customer address1 should be address1 new"    
    assert_equal 'address2 new', customer.address2, "customer address2 should be address2 new"    
    assert_equal 'Calgary', customer.city, "customer city should be Calgary"
    assert_equal 'V5V 5V5', customer.postalcode_zip, "customer postalcode_zip should be V5V 5V5"
    assert_equal 'Alberta', customer.province_state, "customer province_state should be Alberta"
    assert_equal 'Canada', customer.country, "customer country should be Canada"
    assert_equal 'www.sage.com', customer.website, "customer website should be www.sage.com"
    assert_equal '555-555-1717', customer.phone, "customer phone should be 555-555-1717"
    assert_equal '555-555-1818', customer.fax, "customer fax should be 555-555-1818"    
    
  end
  
  def test_should_not_add_customer_with_same_name
    
    assert_difference('Customer.count') do
      post :create, :customer => {
      :name => 'customer name' }
    end
    
    assert_no_difference('Customer.count') do
      post :create, :customer => {
      :name => 'customer name' }
    end
    
    assert_template "customers/new"    
    assert_select "div#errorExplanation"
  end

  def test_should_not_add_customer_without_name
    
    assert_no_difference('Customer.count') do
      post :create, :customer => {
      :address1 => 'address1 new', 
      :address2 => 'address2 new', 
      :city => 'Calgary', 
      :postalcode_zip => 'V5V 5V5', 
      :province_state => 'Alberta', 
      :country => 'Canada', 
      :website => 'www.sage.com', 
      :phone => '555-555-1717', 
      :fax => '555-555-1818' }
    end
    
    assert_template "customers/new"    
    assert_select "div#errorExplanation"
    
  end
  
  def test_should_not_update_customer_with_duplicate_name  
    xhr :put, :update, :id => 1, :customer => { :name => 'Customer with Contacts'} 
    customer = assigns(:customer)
    assert_match(/already exists/, customer.errors.on(:name))
    assert_template "customers/_edit_customer_dialog"
  end
  
  def test_should_check_for_ajax_when_adding_customer_from_invoice
    assert_difference('Customer.count') do 
      xhr :get, :create, :customer => {
        :name => 'customer name' }
      assert_response :success
      assert_template "customers/_new_customer_dialog"
    end 
  end
  
  def test_should_check_for_error_when_adding_customer_from_invoice
    assert_no_difference('Customer.count') do 
      xhr :get, :create, :customer => {
        :name => '' }
    assert_template "customers/_new_customer_dialog"
    # if the error message changes, the assertion below needs to change
    assert_not_nil(@response.body.index('Name  - Customer name is required.'))
    end
  end
  
  def test_should_add_contact
    assert_difference('Contact.count') do 
      put :update, 
      :id => 2,
      :customer=>{
         :contacts_attributes =>
         [
          {:row_id => "contact_new_1",
           :should_destroy => "0",
           :id => "",
           :phone => "555-555-5555 ext. 5555",
           :first_name => "New_Contact_First_Name",
           :last_name => "New_Contact_Last_Name",
           :email => "new_contact@contact-ville.com"}
         ]
      }
      assert_redirected_to :action => 'edit', :id => 2
    end 
  end
  
  def test_ajax_should_add_contact
    assert_difference('Contact.count') do 
      xhr :put, :update, 
      :id => 2,
      :customer=>{
         :contacts_attributes =>
         [
          {:row_id => "contact_new_1",
           :should_destroy => "0",
           :id => "",
           :phone => "555-555-5555 ext. 5555",
           :first_name => "New_Contact_First_Name",
           :last_name => "New_Contact_Last_Name",
           :email => "new_contact@contact-ville.com"}
         ]
      }
      assert_response :success
      assert_template "customers/_edit_customer_dialog"
    end 
  end
  
  def test_ajax_should_update_contact
    assert_no_difference('Contact.count') do 
      xhr :put, :update, 
      :id => 2,
      :customer=>{
         :contacts_attributes =>
         [
          {:row_id => "customer_contact_2",
           :should_destroy =>"0",
           :id => "2",
           :phone => "(604) 555-1212",
           :first_name => "modify first name",
           :last_name => "modify last name",
           :email => "modify@test.com"}
         ]
      }
      assert_response :success
      assert_template "customers/_edit_customer_dialog"
      contact = Contact.find(2)
      assert_not_nil contact
      assert_equal "modify first name", contact.first_name
    end 
  end
  
  def test_should_delete_contact
    customer = customers(:customer_with_contacts)    
    assert_difference('customer.contacts.size', -1) do 
      put :update, 
      :id => 2,
      :customer=>{
         :contacts_attributes =>
         [
          {:row_id => "customer_contact_2",
           :should_destroy =>"1",
           :id => "2",
           :phone => "",
           :first_name => "Alternate_Contact_First_Name",
           :last_name => "Alternate_Contact_Last_Name",
           :email => "alternate_contact@contact-ville.com"}
         ]
      }
      assert_redirected_to :action => 'edit', :id => 2
    end 
  end
  
  def test_ajax_should_delete_contact
    customer = customers(:customer_with_contacts)    
    assert_difference('customer.contacts.size', -1) do 
      xhr :put, :update, 
      :id => 2,
      :customer=>{
         :contacts_attributes =>
         [
          {:row_id => "customer_contact_2",
           :should_destroy =>"1",
           :id => "2",
           :phone => "",
           :first_name => "Alternate_Contact_First_Name",
           :last_name => "Alternate_Contact_Last_Name",
           :email => "alternate_contact@contact-ville.com"}
         ]
      }
      assert_response :success
      assert_template "customers/_edit_customer_dialog"
    end 
  end
  
  
  def test_should_update_contact
    assert_no_difference('Contact.count') do 
      put :update, 
      :id => 2,
      :customer=>{
         :contacts_attributes =>
         [
          {:row_id => "customer_contact_2",
           :should_destroy =>"0",
           :id => "2",
           :phone => "(604) 555-1212",
           :first_name => "modify first name",
           :last_name => "modify last name",
           :email => "modify@test.com"}
         ]
      }
      assert_redirected_to :action => 'edit', :id => 2
      contact = Contact.find(2)
      assert_not_nil contact
      assert_equal "modify first name", contact.first_name
    end 
  end
  
  def test_change_customer_language_on_the_fly
    assert_equal "en_US", Customer.find(2).language
    xhr :post, :change_language, :selected => "fr_FR", :id => 2
    assert_equal "fr_FR", Customer.find(2).language
  end  

  def test_should_update_contact_as_default
    assert_no_difference('Contact.count') do 
      put :update, 
      :id => 2,
      :customer=>{
         :default_contact_id => 2,
         :contacts_attributes =>
         [
          {:row_id => "customer_contact_2",
           :should_destroy =>"0",
           :id => "2",
           :phone => "(604) 555-1212",
           :first_name => "modify first name",
           :last_name => "modify last name",
           :email => "modify@test.com"}
         ]
      }
      assert_redirected_to :action => 'edit', :id => 2
      contact = Contact.find(2)
      assert_not_nil contact
      assert_equal "modify first name", contact.first_name
      customer = assigns(:customer)
      assert_equal 2, customer.default_contact.id
    end 
  end
  
  def test_ajax_should_update_contact_as_default
    assert_no_difference('Contact.count') do 
      xhr :put, :update, 
      :id => 2,
      :customer=>{
         :default_contact_id => 2,
         :contacts_attributes =>
         [
          {:row_id => "customer_contact_2",
           :should_destroy =>"0",
           :id => "2",
           :phone => "(604) 555-1212",
           :first_name => "modify first name",
           :last_name => "modify last name",
           :email => "modify@test.com"}
         ]
      }
      assert_response :success
      assert_template "customers/_edit_customer_dialog"
      contact = Contact.find(2)
      assert_not_nil contact
      assert_equal "modify first name", contact.first_name
      customer = assigns(:customer)
      assert_equal 2, customer.default_contact.id
    end 
  end

  def test_should_create_customer_without_default_contact
    assert_no_difference('Contact.count') do
      assert_difference('Customer.count') do
        post :create, :customer => {
            :name => 'customer name' },
            :default => {:first_name => '', :last_name => '', 
                        :email => '', :phone => ''}
      end
    end
    assert assigns(:customer)
    customer = assigns(:customer)
    assert_redirected_to :action => 'edit', :id => customer.id 
     
  end

  def test_ajax_should_create_customer_without_default_contact
    assert_difference('Customer.count') do 
      xhr :post, :create, :customer => {
        :name => 'customer name' }
      assert_response :success
      assert_template "customers/_new_customer_dialog"
    end 
  end

  def test_should_create_customer_with_default_contact
    assert_difference('Contact.count') do
      assert_difference('Customer.count') do
        post :create, :customer => {
            :name => 'customer name' },
            :default => {:first_name => 'Bob', :last_name => 'Bobbish', 
                        :email => 'bob@valid.com', :phone => ''}
      end
    end
    assert assigns(:customer)
    customer = assigns(:customer)
    assert customer.default_contact
    assert_equal 'Bob', customer.default_contact.first_name
    
    assert_redirected_to :action => 'edit', :id => customer.id 
     
  end
  
  def test_ajax_should_create_customer_with_default_contact
    assert_difference('Customer.count') do 
      assert_difference('Contact.count') do
        xhr :post, :create, :customer => {
          :name => 'customer name'
          },
          :default => {
            :id => "",
            :first_name => "unique first name 3R7A2",
            :last_name => "primary last name",
            :phone => "(604) 555-1212",
            :email => "primary@test.com"
          }
       end
    end 
    assert_response :success
    assert_template "customers/_new_customer_dialog"
    customer = assigns(:customer)
    assert_not_nil customer.default_contact_id
    
    contact = Contact.find(customer.default_contact_id)
    assert_not_nil contact
    assert_equal "unique first name 3R7A2", contact.first_name
  end

  def test_should_update_customer
    put :update, :id => 1, :customer => { :name => 'snazzy name'}
    customer = assigns(:customer)
    assert_equal 'snazzy name', customer.name
    assert_redirected_to :action => 'edit', :id => customer.id
    
    xhr :put, :update, :id => 2, :customer => { :name => 'cool name'} 
    customer = assigns(:customer)
    assert_equal 'cool name', customer.name
    assert_response :success
    assert_template "customers/_edit_customer_dialog"
  end

  def test_should_update_customer_with_one_contact
    # This tests a special case where the form only allows entry of one contact.
    xhr :put, :update, :id => 2, :customer => {
      "default_contact"=>{
        "email"=>"my_only_contact@contact-ville.com"}
    } 
    customer = assigns(:customer)
    assert_equal 'my_only_contact@contact-ville.com', customer.default_contact.email
    assert_template "customers/_edit_customer_dialog"
  end
  
  def test_should_accept_new_contact_as_default
    # This test covers the case where the default contact is a new contact.  
    # New contacts do not have real IDs, but they have a special row_id. 
    customerParams = {
      "default_contact_id"=>"contact_new_1",
      "contacts_attributes"=> [
        {"row_id"=>"contact_new_1",
        "should_destroy"=>"0",
        "id"=>"",
        "phone"=>"555-555-5555 ext. 5555",
        "first_name"=>"New_Contact_First_Name",
        "last_name"=>"New_Contact_Last_Name",
        "email"=>"New_contact@contact-ville.com"
        }
      ]
    }
    
    assert_difference('Contact.count') do
      assert_no_difference('Customer.count') do
        put :update, :id => 2,  "customer"=> customerParams 
       end
    end
    assert assigns(:customer)
    customer = assigns(:customer)
    assert customer.default_contact
    assert_equal 'New_Contact_First_Name', customer.default_contact.first_name
    assert_redirected_to :action => "edit", :id => customer.id

    customerParams["contacts_attributes"][0]["first_name"] = "Second_New_Contact_First_Name"
    customerParams["contacts_attributes"][0]["email"] = "New_contact_2@contact-ville.com"
    assert_difference('Contact.count') do
      assert_no_difference('Customer.count') do
        xhr :put, :update, :id => 2,  "customer"=> customerParams
       end
    end
    assert assigns(:customer)
    customer = assigns(:customer)
    assert customer.default_contact
    assert_equal 'Second_New_Contact_First_Name', customer.default_contact.first_name
    assert_template 'customers/_edit_customer_dialog'       
  end

  def test_should_destroy_customer
    assert_difference('Customer.count', -1) do
      delete :destroy, :id => 1
    end

    
  end

  # paging and filtering for user story 29, trac #71
  # TODO: copy working filter tests to unit tests to increase coverage.
  def test_should_find_customer_by_name
    login_as :customer_list_user
    # ask for customer with name "paid"
    get :index, :filters=>{:name=>'paid'}
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers).kind_of?(PagingEnumerator), "customers should be a PagingEnumerator"
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).page_size
    assert_equal 3, assigns(:customers).results.length
    assert assigns(:customers).results.any?{|c| c == customers(:customer_with_invoices_none_paid)}
    assert assigns(:customers).results.any?{|c| c == customers(:customer_with_invoices_partially_paid)}
    assert assigns(:customers).results.any?{|c| c == customers(:customer_with_invoices_all_paid)}
  end
  
  def test_should_find_customer_by_contact_name
    login_as :customer_list_user
    # ask for customer with contact name Contact_1
    get :index, :filters=>{:contact_name=>'Contact_1'}
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers).kind_of?(PagingEnumerator), 'customers should be a PagingEnumerator'
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).page_size
    assert_equal 1, assigns(:customers).results.length
    assert assigns(:customers).results.first == customers(:customer_list_user_customer_1)
  end
  
  def test_should_find_customer_by_contact_phone_number
    login_as :customer_list_user
    # ask for customer with contact phone number x
    get :index, :filters=>{:contact_phone=>'5678'}
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers).kind_of?(PagingEnumerator), 'customers should be a PagingEnumerator'
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).page_size
    assert_equal 1, assigns(:customers).results.length
    assert assigns(:customers).results.first == customers(:customer_list_user_customer_2)
  end
  
  def test_should_find_customer_by_contact_email
    login_as :customer_list_user
    # ask for customer with contact e-mail 'example.com'
    get :index, :filters=>{:contact_email=>'example.com'}
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers).kind_of?(PagingEnumerator), 'customers should be a PagingEnumerator'
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).page_size
    assert_equal 2, assigns(:customers).results.length
    assert assigns(:customers).results.any?{|c| c == customers(:customer_list_user_customer_1)}
    assert assigns(:customers).results.any?{|c| c == customers(:customer_list_user_customer_3)}
  end
  
  def test_should_remember_search_filter_settings
    get :index, :filters=>{:contact_name=>'name', :something => 'blah'}
    assert_response :success
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal 'name', assigns(:filters).contact_name
    assert_equal 'blah', assigns(:filters).something
  end
  
  def test_should_clear_search_filter_settings
    get :index, :filters=>{:name=>'some name', :something => 'blah', :clear => 'Clear'}
    assert_response :success
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal nil, assigns(:filters).name
    assert_equal nil, assigns(:filters).something
  end

  def test_should_paginate_customer_list
    login_as :heavy_user
    get :index
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers).kind_of?(PagingEnumerator)
    assert assigns(:customers).size > ::AppConfig.pagination.customers.page_size
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).page_size
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).results.length
    first = assigns(:customers).results.first
    
    get :index, :page => 2
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers).kind_of?(PagingEnumerator)
    assert assigns(:customers).size > ::AppConfig.pagination.customers.page_size
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).page_size
    assert_equal ::AppConfig.pagination.customers.page_size, assigns(:customers).results.length
    assert assigns(:customers).results.first.id != first.id
  end
  
  def test_should_not_lose_new_contact_after_customer_error
    
    assert_no_difference('Contact.count') do 
      put :update, 
      :id => 2,
      :customer=>{
         :name => "",
         :contacts_attributes =>
         [
          {:row_id => "contact_new_1",
           :should_destroy => "0",
           :id => "",
           :phone => "555-555-5555 ext. 5555",
           :first_name => "don't lose first name",
           :last_name => "don't lose last name",
           :email => "dontlose@mac.com"}
         ]
      }
      assert_response :success
      assert_template "customers/edit"
      assert_select "div#errorExplanation"
      assert_select "tr#customer_contact_1", {:count=>1}
      assert_select "tr#customer_contact_2", {:count=>1}
      assert_select "tr#customer_contact_new_1", {:count=>1}      
      assert_select "tr.child_item", {:count=>3}  
      
    end 
  end

  def test_ajax_should_not_lose_new_contact_after_customer_error
    
    assert_no_difference('Contact.count') do 
      xhr :put, :update, 
      :id => 2,
      :customer=>{
         :name => "",
         :contacts_attributes =>
         [
          {:row_id => "contact_new_1",
           :should_destroy => "0",
           :id => "",
           :phone => "555-555-5555 ext. 5555",
           :first_name => "don't lose first name",
           :last_name => "don't lose last name",
           :email => "dontlose@mac.com"}
         ]
      }
      assert_template "customers/_edit_customer_dialog"
      assert_select "div#errorExplanation"
      assert_select "tr#customer_contact_1", {:count=>1}
      assert_select "tr#customer_contact_2", {:count=>1}
      assert_select "tr#customer_contact_new_1", {:count=>1}      
      assert_select "tr.child_item", {:count=>3}  
      
    end 
  end

  def test_should_not_lose_primary_contact_after_new_customer_error
    
    assert_no_difference('Customer.count') do
      assert_no_difference('Contact.count') do 
        post :create, 
        :customer=>{
           :name => "",
           :contacts_attributes =>
           [
            {:row_id => "contact_new_1",
             :should_destroy => "0",
             :id => "",
             :phone => "555-555-5555 ext. 5555",
             :first_name => "don't lose first name",
             :last_name => "don't lose last name",
             :email => "dontlose@mac.com"}
           ]
        }
        assert_template "customers/new"
        assert_select "div#errorExplanation"
        assert_select "input#customer_contacts_attributes__first_name", 
          {:value=>"don't lose first name"}
        assert_select "input#customer_contacts_attributes__last_name", 
          {:value=>"don't lose last name"}      
        assert_select "input#customer_contacts_attributes__email", 
          {:value=>"dontlose@mac.com"}      
      end    
    end
  end
  
  def test_ajax_should_not_lose_primary_contact_after_new_customer_error
    
    assert_no_difference('Customer.count') do
      assert_no_difference('Contact.count') do 
        xhr :post, :create, 
        :customer=>{
           :name => "",
           :contacts_attributes =>
           [
            {:row_id => "contact_new_1",
             :should_destroy => "0",
             :id => "",
             :phone => "555-555-5555 ext. 5555",
             :first_name => "don't lose first name",
             :last_name => "don't lose last name",
             :email => "dontlose@mac.com"}
           ]
        }
        assert_template "customers/_new_customer_dialog"
        assert_select "div#errorExplanation"
        assert_select "input#default_first_name", 
          {:value=>"don't lose first name"}
        assert_select "input#default_last_name", 
          {:value=>"don't lose last name"}      
        assert_select "input#default_email", 
          {:value=>"dontlose@mac.com"}      
      end    
    end
  end
   
  def test_should_not_lose_contact_edit_after_customer_error
    assert_no_difference('Contact.count') do 
      put :update, 
      :id => 2,
      :customer=>{
         :name => "",
         :contacts_attributes =>
         [
          {:row_id => "contact_new_1",
           :should_destroy => "0",
           :id => "",
           :phone => "555-555-5555 ext. 5555",
           :first_name => "Don't add first",
           :last_name => "Don't add last",
           :email => "dontadd@mac.com"}
         ]
      }
      assert_response :success
      assert_template "customers/edit"
      assert_select "div#errorExplanation"
      assert_select "tr#customer_contact_1", {:count=>1}
      assert_select "tr#customer_contact_1 td", {:count=>6}
      
      #assert_select "tr[id=customer_contact_1] td input[id=customer_contacts_attributes__first_name]", {:count=>1}      
      assert_select "tr#customer_contact_1" do
        assert_select "td" do
          assert_select "input#customer_contacts_attributes__first_name", 
            {:count=>1}             
        end
      end
      
      #assert_select "tr[id=customer_contact_1] td input[id=customer_contacts_attributes__first_name]", {:value=>"Basic_Contact_First_Name"}
      
      assert_select "tr#customer_contact_1" do
        assert_select "td" do
          assert_select "input#customer_contacts_attributes__first_name", 
            {:value=>"Modified First Name"}   
        end
      end  
    end 
  end  

  def test_ajax_should_not_lose_contact_edit_after_customer_error
    assert_no_difference('Contact.count') do 
      xhr :put, :update, 
      :id => 2,
      :customer=>{
         :name => "",
         :contacts_attributes =>
         [
          {:row_id => "contact_new_1",
           :should_destroy => "0",
           :id => "",
           :phone => "555-555-5555 ext. 5555",
           :first_name => "Don't add first",
           :last_name => "Don't add last",
           :email => "dontadd@mac.com"}
         ]
      }
      assert_template "customers/_edit_customer_dialog"
      assert_select "div#errorExplanation"
      assert_select "tr#customer_contact_1", {:count=>1}
      assert_select "tr#customer_contact_1 td", {:count=>6}
      
      #assert_select "tr[id=customer_contact_1] td input[id=customer_contacts_attributes__first_name]", {:count=>1}      
      assert_select "tr#customer_contact_1" do
        assert_select "td" do
          assert_select "input#customer_contacts_attributes__first_name", 
            {:count=>1}             
        end
      end
      
      #assert_select "tr[id=customer_contact_1] td input[id=customer_contacts_attributes__first_name]", {:value=>"Basic_Contact_First_Name"}
      
      assert_select "tr#customer_contact_1" do
        assert_select "td" do
          assert_select "input#customer_contacts_attributes__first_name", 
            {:value=>"Modified First Name"} 
        end
      end  
    end 
  end  

  def test_should_not_save_primary_contact_after_customer_error
    assert_no_difference('Contact.count') do 
      put :update, 
      :id => 1,
      :customer=>{
         :name => "",
         :contacts_attributes=>[{:row_id=>"contact_new_1", 
            :should_destroy=>"0", 
            :id=>"", 
            :first_name => 'Primary first name', 
            :last_name => 'Primary last name', 
            :email => 'primary@test.com', 
            :phone => '(555) 555-5555'
            }] 
      }
      assert_response :success
      assert_template "customers/edit"
      assert_select "div#errorExplanation"
      #puts @response.body  
      #assert_select "tr.contact_container td input#customer_default_contact_first_name", {:value=>"Primary first name"}      
      
      assert_select "tr#customer_contact_new_1" do
        assert_select "td" do
          assert_select "input#customer_contacts_attributes__first_name", 
            {:value=>"Primary first name"}                        
        end
      end
      
    end 
  end

  def test_ajax_should_not_save_primary_contact_after_customer_error
    assert_no_difference('Contact.count') do 
      xhr :put, :update, 
      :id => 1,
      :customer=>{
         :name => "",
         :contacts_attributes=>[{:row_id=>"contact_new_1", 
            :should_destroy=>"0", 
            :id=>"", 
            :first_name => 'Primary first name', 
            :last_name => 'Primary last name', 
            :email => 'primary@test.com', 
            :phone => '(555) 555-5555'
            }] 
      }
      assert_template "customers/_edit_customer_dialog"
      assert_select "div#errorExplanation"
      #puts @response.body  
      #assert_select "tr.contact_container td input#customer_default_contact_first_name", {:value=>"Primary first name"}      
      
      assert_select "tr#customer_contact_new_1" do
        assert_select "td" do 
          assert_select "input#customer_contacts_attributes__first_name", 
            {:value=>"Primary first name"}                              
        end
      end
      
    end 
  end
  
#  def test_ajax_should_delete_primary_contact_from_invoice
#  
#    # update primary contact      
#    xhr :put, :update, 
#    :id => 2,
#    :customer=>{
#       :default_contact_id => "1",
#    }
#    assert_response :success
#    assert_template "customers/_edit_customer_dialog"
#    
#    customer = assigns(:customer)    
#    assert_difference('customer.contacts.size', -1) do 
#      xhr :put, :update, 
#      :id => 2,
#      :customer=>{
#         :contacts_attributes =>
#         [
#          {:row_id => "customer_contact_1",
#           :should_destroy => "1",
#           :id => "1",
#           :phone => "",
#           :first_name => "Basic_Contact_First_Name",
#           :last_name => "Basic_Contact_Last_Name",
#           :email => "basic_contact@contact-ville.com"}
#         ]
#      }
#      # reload customer
#      customer = assigns(:customer)
#      assert_equal 2, customer.default_contact_id, "primary contact id should be 2"
#      assert_response :success
#      assert_template "customers/_edit_customer_dialog"
#    end 
#  end

  def test_switch_country
    xhr :post, :switch_country, :id => 2 
    assert_rjs :replace_html, 'div_country_dependent' 
  end    
    
  def test_switch_country_customer_is_nil
    xhr :post, :switch_country, :customer => {:name => "myName"} 
    assert_rjs :replace_html, 'div_country_dependent' 
  end
  
  def test_set_country_from_default_country
    get :new
    customer = assigns(:customer)
    assert_equal users(:basic_user).profile.company_country, customer.country
  end
  
  def test_set_country_from_http_accept_language
    
    Profile.any_instance.stubs(:country).returns('')
    
    languages = [{:code => "en-us", :country => "US"}, 
                 {:code => "en-ca", :country => "CA"}, 
                 {:code => "en-gb", :country => "GB"}]
     
    languages.each do | language |
      @request.env['HTTP_ACCEPT_LANGUAGE'] = language[:code]
      get :new
      customer = assigns(:customer)
      assert_equal language[:country], customer.country
    end
  end  
   
  def test_should_load_overview
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :overview
    assert_response :success
  end

  def test_should_load_past_due_overview_as_json
    # basic sanity check that overview_data creates filters object, and fetches the overdue invoice in users(:basic)
    # TODO: these tests could be better factored to isolate testing what the controller does rather than just the end result
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :overview, :limit => '10'
    assert_response :success
    
    assert_not_nil assigns(:filters)
    assert_match(/"total": 3/, @response.body)
  end

  
  def test_should_load_overview
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :overview
    assert_response :success
  end

  def test_should_load_past_due_overview_as_json
    # basic sanity check that overview_data creates filters object, and fetches the overdue invoice in users(:basic)
    # TODO: these tests could be better factored to isolate testing what the controller does rather than just the end result
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :overview, :limit => '10'
    assert_response :success
    
    assert_not_nil assigns(:filters)
    assert_match(/"total": 3/, @response.body)
  end
 
    def test_get_index_csv
      get :index, :format => "csv"
      assert_response :success
      assert @response.body.include?("customer_name")
      assert @response.body.include?("customer_address1")
      assert @response.body.include?("contact_first_name")
      assert @response.body.include?("contact_last_name")
      assert @response.headers["type"].include?("text/csv")
      assert_not_nil assigns(:customers)
     end
     
    def test_should_import_csv_file
      fdata = fixture_file_upload('/files/existing_customer_with_contacts.csv', 'text/csv')
      post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      
      assert_response :success
    end
  
    def test_import_should_not_overrite_existing_customer
      customer = customers(:customer_with_no_contacts)
      assert_no_difference('Customer.count') do 
        fdata = fixture_file_upload('/files/existing_customer.csv', 'text/csv')
        post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      end
      assert_match(/No new customers were imported./, flash[:warning])
    end
      
    def test_import_should_not_overrite_existing_contacts
      customer = customers(:customer_with_contacts)
      assert_no_difference('Contact.count') do 
        fdata = fixture_file_upload('/files/existing_customer.csv', 'text/csv')
        post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      end
      assert_match(/No new customers were imported./, flash[:warning])
    end
    
    def test_import_should_add_contacts_to_existing_customer
      customer = customers(:customer_with_no_contacts)    
      
      assert_difference('Contact.count', +3) do 
        fdata = fixture_file_upload('/files/existing_customer_with_contacts.csv', 'text/csv')
        post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      end
      assert_match(/Customer list was updated./, flash[:notice])
      assert_equal "Bill", customer.contacts.first.first_name
      assert_equal "Gates", customer.contacts.first.last_name
      assert_equal "bgates@microsft.com", customer.contacts.first.email
      assert_equal "5551212", customer.contacts.first.phone
    end
    
    def test_import_should_create_new_customer_with_contacts      
      assert_difference('Customer.count', +2) do
        fdata = fixture_file_upload('/files/new_customer_with_contacts.csv', 'text/csv')
        post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      end
      
      assert_match(/2 customers imported./, flash[:notice])
      
      assert_equal "new_customer", Customer.find_by_name("new_customer").name
      assert_equal "addr1", Customer.find_by_name("new_customer").address1
      assert_equal "addr2", Customer.find_by_name("new_customer").address2
      assert_equal "city", Customer.find_by_name("new_customer").city
      assert_equal "province", Customer.find_by_name("new_customer").province_state
      assert_equal "zip", Customer.find_by_name("new_customer").postalcode_zip
      assert_equal "CA", Customer.find_by_name("new_customer").country
      assert_equal "example.com", Customer.find_by_name("new_customer").website
      assert_equal "1111", Customer.find_by_name("new_customer").phone
      assert_equal "2222", Customer.find_by_name("new_customer").fax
# RADAR ticket:1522 -- different results on different machines
#      assert_equal "en", Customer.find_by_name("new_customer").language
    end
    
    def test_import_should_create_contacts_when_creating_new_customer
      assert_difference('Contact.count', +3) do
        fdata = fixture_file_upload('/files/new_customer_with_contacts.csv', 'text/csv')
        post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      end
    end
    
    def test_should_not_import_invalid_fixtures
      fdata = fixture_file_upload('/files/invalid_contacts.csv', 'image/png')
      
      assert_no_difference 'Customer.count' do
        post :import, :csv_import => {:file => fdata}, :html => { :multipart => true }
      end 
    end
  
  def test_mobile_version_view_new
    get :new, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end

  def test_mobile_version_view_edit
    get :edit, :id => 1, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end
  
  def test_mobile_version_on_invalid_submit_new

    get :new, :mobile => 'true'
    post :create, :customer => {}
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end

  def test_mobile_version_on_invalid_submit_edit

    get :edit, :id => 1, :mobile => 'true'
    put :update, :id => 1, :customer => {
      :name => '' }
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("prohibited this customer from being saved")
  end
  
  def test_single_default_params_update_on_edit
    get :edit, :id => 1, :mobile => 'true'
    put :update, :id => 1, :customer => {:name => "mobile customer"}, :default => {
      :first_name => 'mobile_first_name' }
    assert_response :redirect
    customer = Customer.find(1)
    assert_equal "mobile_first_name", customer.default_contact.first_name
  end

  def test_mobile_overview

    get :overview, :mobile => "true"
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("Customer with no contacts")
  end
  
  def test_mobile_details
    get :details, :id => 1, :mobile => 'true'
    assert_response :success
    assert @response.body.include?("mobile.css")
  end

end
