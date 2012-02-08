require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < Test::Unit::TestCase
  fixtures :customers, :invoices, :payments, :pay_applications, :users, :contacts

  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  # Replace this with your real tests.
  def test_default_contact_returns_first_contact_if_not_set
    rb = customers(:customer_with_no_contacts)

    assert_nil rb.default_contact, "default_contact should return nil if no contacts"
    
    first_contact = rb.contacts.build(:first_name => 'first')
    second_contact = rb.contacts.build(:first_name => 'second')
    
    assert_equal first_contact, rb.default_contact, "default_contact should return the first contact in the contact list"
    
    rb.default_contact = second_contact
    rb.save
    
    assert_equal second_contact, rb.default_contact, "default_contact returns the set default contact"
  end
  
  def test_on_the_fly_creation_of_contact
    rb = customers(:customer_with_no_contacts)
    
#    assert_equal 0, rb.contacts.length
    assert true
    
    rb.contacts_attributes = [{:first_name => 'new'}]
    assert_equal 1, rb.contacts.length
    assert_equal "new", rb.contacts.first.first_name
  end
  
  # user story 29, trac #71
  # test calculation of balance owing for customer.
  def test_should_have_no_amount_owing
    c = customers(:customer_with_invoices_all_paid)
    assert_equal 0, c.amount_owing, 'should have zero balance owing.'

    c = customers(:customer_with_no_invoices)
    assert_equal 0, c.amount_owing, 'should have zero balance owing.'
  end
  
  def test_should_have_postive_amount_owing
    c = customers(:customer_with_invoices_partially_paid)
    assert_not_equal 0, c.amount_owing, 'customer_some_invoices_paid should have balance owing.'

    
    c = customers(:customer_with_invoices_none_paid)
    assert_not_equal 0, c.amount_owing, 'customer_no_invoices_paid should have balance owing.'
  end

  # tests adapted from customers_controller test.
  def test_should_find_customer_by_name
    filters = OpenStruct.new({:name=>'paid'})
    filters.page = {:current => 0, :size => 100}
    customers = Customer.filtered_customers(users(:customer_list_user).customers, filters)
    assert_equal 3, customers.size
    assert customers.any?{|c| c == customers(:customer_with_invoices_none_paid)}
    assert customers.any?{|c| c == customers(:customer_with_invoices_partially_paid)}
    assert customers.any?{|c| c == customers(:customer_with_invoices_all_paid)}
  end
  
  def test_should_find_customer_by_contact_name
    filters = OpenStruct.new({:contact_name=>'Contact_1'})
    filters.page = {:current => 0, :size => 100}
    customers = Customer.filtered_customers(users(:customer_list_user).customers, filters)
    assert_equal 1, customers.size
    assert customers.all?{|c| c == customers(:customer_list_user_customer_1)}
  end
  
  def test_should_find_customer_by_contact_phone_number
    filters = OpenStruct.new({:contact_phone=>'5678'})
    filters.page = {:current => 0, :size => 100}
    customers = Customer.filtered_customers(users(:customer_list_user).customers, filters)
    assert_equal 1, customers.size
    assert customers.all?{|c| c == customers(:customer_list_user_customer_2)}
  end
  
  def test_should_find_customer_by_contact_email
    filters = OpenStruct.new({:contact_email=>'example.com'})
    filters.page = {:current => 0, :size => 100}
    customers = Customer.filtered_customers(users(:customer_list_user).customers, filters)
    assert_equal 2, customers.size
    assert customers.any?{|c| c == customers(:customer_list_user_customer_1)}
    assert customers.any?{|c| c == customers(:customer_list_user_customer_3)}
  end

  def test_should_create_json_for_grid_view
    u = users(:basic_user)
    puts "u.customers: #{u.customers.inspect}" if $log_on
    u.customers.each {|c| c.expects(:amount_owing).returns(BigDecimal("#{c.id}.#{c.id}"))}
    hash = {:customers => u.customers, :total => u.customers.size}
    json_raw = hash.to_json(Customer.list_json_params)
    assert_not_nil json_raw
    json = ActiveSupport::JSON.decode(json_raw)
    assert_not_nil json['customers']
    assert_equal 3, json['customers'].length, "basic user has 3 customers"


    assert_equal 'Customer with Contacts', json['customers'][0]['name']
    assert_equal 'basic_contact@contact-ville.com', json['customers'][0]['contact_email']
    
    assert_equal 'Basic_Contact_First_Name Basic_Contact_Last_Name', json['customers'][0]['contact_name']
    assert_equal '2', json['customers'][0]['id'].to_s
    assert_equal '(444)444-4444', json['customers'][0]['phone'].to_s
    assert_equal 2.2, json['customers'][0]['amount_owing']
    
  end
  
  def test_should_return_contact_name_or_dash
    assert_equal '-', customers(:customer_with_no_contacts).contact_name
    assert_equal 'Basic_Contact_First_Name Basic_Contact_Last_Name', customers(:customer_with_contacts).contact_name
  end
  
  def test_should_return_contact_email_or_dash
    assert_equal '-', customers(:customer_with_no_contacts).contact_email
    assert_equal 'basic_contact@contact-ville.com', customers(:customer_with_contacts).contact_email
  end
  
  def test_should_prune_empty_contacts_from_customer
    customer = customers(:customer_with_contacts)
    
    # attempt to add a blank contact
    assert_no_difference('customer.contacts.size') do
      blank_contact = customer.contacts.build()
      customer.save    
      customer.prune_empty_contacts(true)
    end

    # add a blank contact and a valid contact
    assert_difference('customer.contacts.size', 1) do
      blank_contact = customer.contacts.build()
      customer.save            
      valid_contact = customer.contacts.build(:first_name => 'first', :last_name => 'last')
      customer.save      
      customer.prune_empty_contacts(true)
    end
    
  end  

  def test_should_find_all_customers_for_select
    u = users(:basic_user)
    customers = u.customers.find_for_select
    assert_equal 3, customers.length
    assert_equal u.customers.first.name, customers.first.first
  end
  
  def test_should_assign_default_contact_by_hash
    cust = customers(:customer_with_contacts)
    cust.default_contact = cust.contacts.first
    contact = cust.default_contact
    cust.save!
    cust.default_contact = {
      :first_name => 'new first_name', 
      :last_name => 'new last_name',
      :email => 'new@email.com',
      :phone => '7777773'
    }
    # assert cust.default_contact_id != contact.id, "setting default_contact to a hash should create a new contact"
    # assert cust.default_contact.new_record?
    cust.save!
    assert !cust.default_contact.new_record?
    assert_equal 'new first_name', cust.default_contact.first_name
    assert_equal 'new last_name', cust.default_contact.last_name
    assert_equal 'new@email.com', cust.default_contact.email
    assert_equal '7777773', cust.default_contact.phone
  end
  
  def test_should_return_list_json_params
    assert Customer.list_json_params.is_a?(Hash)
  end
  
  def test_should_add_contact_by_name
    cust = add_valid_customer(users(:basic_user), :contacts => nil)
    assert_nil cust.default_contact
    
    cust.contact_name = "Bob"
    
    assert_not_nil(cust.default_contact)
    assert_equal("Bob", cust.default_contact.first_name)
    
    cust.contact_name = "Jones, Bob"
    assert_equal("Bob", cust.default_contact.first_name)
    assert_equal("Jones", cust.default_contact.last_name)
    
    cust.contact_name = "Jones, Bob, the dude"
    assert_equal("Jones, Bob, the dude", cust.default_contact.first_name)
    
  end
end
