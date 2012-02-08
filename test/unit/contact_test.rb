require File.dirname(__FILE__) + '/../test_helper'

class ContactTest < Test::Unit::TestCase
  fixtures :contacts, :customers, :users

  def test_name_is_first_and_last_name_or_email
    c_first_name_only = Contact.new(
      {:first_name => 'Bob',
       :email => 'bob@somewhere.com'}
    )
    assert_equal "Bob", c_first_name_only.name, "name should be first name if supplied"

    c_last_name_only = Contact.new(
      {:last_name => 'Somebody',
       :email => 'bob@somewhere.com'}
    )
    assert_equal "Somebody", c_last_name_only.name, "name should be last name if no first name supplied"
    
    c_first_and_last_name = Contact.new(
      { :first_name => 'Bob',
        :last_name => 'Somebody',
        :email => 'bob@somewhere.com'}
    )
    assert_equal "Bob Somebody", c_first_and_last_name.name, "name should be first_name and last_name joined by a space if both supplied"
    
    c_email_only = Contact.new(
      { :first_name => '',
        :last_name => '',
        :email => 'bob@somewhere.com'}
    )
    assert_equal "bob@somewhere.com", c_email_only.name, "name should be email if no first_name or last_name supplied"
    
  end
  
  def test_should_know_if_it_is_the_default_contact
    cust = add_valid_customer(User.find(:first), :contacts => false)
    c1 = add_valid_contact(cust)
    c2 = add_valid_contact(cust)
    c3 = add_valid_contact(cust)
    assert c1.is_default?, "first created contact should be default"
    assert ! c2.is_default?
    assert ! c3.is_default?
    cust.default_contact = c2
    cust.save
    c1.reload
    c2.reload
    c3.reload
    assert ! c1.is_default?, "after explicitly setting default contact, first created contact should no longer be default"
    assert c2.is_default?
    assert ! c3.is_default?
  end
  
  def test_null_out_customer_default_contact
    cust = add_valid_customer(User.find(:first), :contacts => false)
    c1 = add_valid_contact(cust)
    assert c1.is_default?, "first created contact should be default"
    
    assert_difference('Contact.count', -1) do
      c1.destroy
    end
    
    assert_nil cust.default_contact_id
    
  end
  
  def test_should_find_fuzzy
    Contact.create(
      :first_name => 'Bob',
      :last_name => 'Jones',
      :email => 'bob.jones@test.com'
    )
    
    deny Contact.find_fuzzy('bob').empty?
    deny Contact.find_fuzzy('b*b').empty?
    deny Contact.find_fuzzy('b?b').empty?
    deny Contact.find_fuzzy('jones').empty?
    deny Contact.find_fuzzy('jon').empty?
    deny Contact.find_fuzzy('*ones').empty?
    deny Contact.find_fuzzy('test.com').empty?
    assert Contact.find_fuzzy('tost.com').empty?
    assert Contact.find_fuzzy('tost.*').empty?
    assert Contact.find_fuzzy('ko').empty?
    assert Contact.find_fuzzy('b??b').empty?
    deny Contact.find_fuzzy('bob', {:conditions => "last_name <> 'Jones'"}).empty?
     
  end
 
  def test_formatted_email
    c = Contact.new(
      { :first_name => 'Bob',
        :last_name => 'Somebody',
        :email => 'bob@somewhere.com'}
    )
    assert_equal "Bob Somebody <bob@somewhere.com>", c.formatted_email
  end
  
  def test_should_find_all_contacts_for_select
    c = customers(:customer_with_contacts)
    contacts = c.contacts.find_for_select
    assert_equal 2, contacts.length
    assert_equal c.contacts.first.name, contacts.first.first
  end  
  
 def test_disallow_invalid_email_in_contact
    cust = Customer.new
    cust.name = "company"
    cust.created_by_id = 1
    
    assert cust.valid?
    
    contact = Contact.new
    
    contact.email = "asdf"
    deny contact.valid?
    
    cust.contacts << contact
    deny cust.valid?
    
    contact.email = "asdf@asdf.com"
    assert contact.valid?
    
    cust = Customer.new
    cust.name = "company"
    cust.created_by_id = 1
    
    cust.contacts << contact
    assert cust.valid?
  end
 
end
