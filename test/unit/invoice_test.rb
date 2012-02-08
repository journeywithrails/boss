require File.dirname(__FILE__) + '/../test_helper'
include Sage::BusinessLogic::Exception

unless Invoice
  require 'invoice'
end

class Invoice
    def unique_type #for testing purposes
      if self.unique_number.nil? and self.unique_name.nil?
        'neither'
      elsif !self.unique_number.nil? and self.unique_name.nil?
        'number'
      elsif self.unique_number.nil? and !self.unique_name.nil?
        'name'
      elsif !self.unique_number.nil? and !self.unique_name.nil?
        'both'
      end  
    end  
end

module InvoiceTestHelpers
  private
  ##############  Stays at bottom ####################################
  def valid_invoice(opts={})
    InvoiceTest.guaranteed_unique ||= 98765
    InvoiceTest.guaranteed_unique += 1
    {
      :unique => InvoiceTest.guaranteed_unique,
      :created_by => users(:user_without_invoices),
      :description => 'an invoice',
      :total_amount => BigDecimal.new('1'),
      :currency => "USD"
    }.merge(opts)
  end
  
  def valid_invoice_obj(save=true, opts={})
    i = save ? Invoice.create(valid_invoice(opts)) : Invoice.new(valid_invoice(opts))
  end
  
  def valid_line_item
    {
      :quantity => BigDecimal.new('1'),
      :price => BigDecimal.new('1')
    }
  end
  
  def valid_customer
    {:name => 'AoSome Customer'}
  end
  
  # get rid of all invoices so that we can test stuff without worrying about colliding with fixtures
  def delete_invoices
    Invoice.connection.execute('delete from invoices')
  end

  def setup_dated_invoices
    delete_invoices
    u=users(:basic_user)
    d=Date.today
    3.times do
      i = valid_invoice_obj(true, {:date => 1.day.ago, :created_by => u})
    end
    2.times do
      i = valid_invoice_obj(true, {:date => (d + 1.day), :created_by => u})
    end
    i = valid_invoice_obj(true, {:date => (d + 2.days), :created_by => u})
  end
end

class InvoiceTest < ActiveSupport::TestCase
  include InvoiceTestHelpers
  class << self
    attr_accessor :guaranteed_unique
  end
  
  fixtures :invoices
  fixtures :users
  fixtures :customers
  ##############  User Story 7 ####################################

  uses_transaction :test_should_automatically_assign_unique_invoice_number_per_user

  def teardown
    $log_on = false
  end

  def test_should_create_quote
    i = invoices(:invoice_with_line_items)
    assert ! i.quote?
    i.save_quote!
    assert i.quote?
  end

  def test_should_convert_quote_to_invoice
    i = invoices(:quote)
    i.save_draft!
    assert_equal i.invoice_or_quote, "Invoice"
  end
  
  def test_should_create_customer_on_the_fly
    i = invoices(:invoice_with_no_customer)
    i.unique = 98765
    assert_nil i.customer

    i.customer_attributes = {:name => 'new'}

    assert_not_nil i.customer
    assert_equal "new", i.customer.name
    assert_equal i.created_by_id, i.customer.created_by_id
    assert i.save
  end

  def test_should_create_contact_on_the_fly
    i = invoices(:invoice_with_no_customer)
    i.unique = 98765
    
    assert_nil i.customer
    
    i.contact_attributes = {:first_name => 'newcontact'}
    assert_not_nil i.contact
    assert_raise Sage::BusinessLogic::Exception::OrphanedContactException do
      i.save
    end

    i.customer = customers(:customer_with_no_contacts)

    assert_nothing_raised Sage::BusinessLogic::Exception::OrphanedContactException do
      i.save
    end
    
    assert_raise Sage::ActiveRecord::Exception::ConditionsViolatedException do
      i.contact = contacts(:alternate_contact)
    end
    
  end
  
     
  
  ##############  User Story 4 ####################################
  
  def test_should_automatically_assign_unique_invoice_number_per_user
    delete_invoices
    u=users(:user_without_invoices)

    i1 = u.invoices.create()
    i1.save
    assert_equal "1", i1.unique.to_s, "first ever invoice should be number 1"


    i2 = u.invoices.create()
    i2.unique = 4
    i2.save
    assert_equal "4", i2.unique.to_s, "number can be set manually if it does not exist"


    i5 = u.invoices.create()
    i5.save
    assert_equal "5", i5.unique.to_s, "invoice number should be one more than highest number so far, even with gaps"
    i3 = u.invoices.build
    i3.unique = 3
    i3.save
    assert_equal "3", i3.unique.to_s, "ok to set invoice to have a number in a gap"
    
    i6 = u.invoices.create
    assert_equal "6", i6.unique.to_s, "after gap is filled, make sure don't reuse a number"
    #i6.unique = 3

    i7 = u.invoices.build
    i7.unique = 'some text'
    i7.save
    assert_equal "some text", i7.unique.to_s, "This text should be saved to unique_name column"


    i8 = u.invoices.build
    i8.unique = 999999999
    i8.save
    assert_equal "999999999", i8.unique.to_s, "number can be set manually if it does not exist"


    i9 = u.invoices.build
    i9.unique = 9999999999999999999
    i9.save
    assert_equal "9999999999999999999", i9.unique.to_s, "Now this number should be saved in unique_name column"

    i10 = u.invoices.create()
    assert i10.save
    assert_not_nil i10.unique_number

    i11 = u.invoices.create()
    assert i11.save
    assert_not_nil i11.unique_number

    #assert i6.save! == false, "cannot save duplicate"
    #assert_not_valid i6, "don't allow setting non-unique number"
  end


  ##############  User Story 8 ####################################

  def test_should_create_line_items_from_params
    i = Invoice.find(invoices(:invoice_with_no_line_items).id)
    
    assert_equal 0, i.line_items.length
    #assert_empty i.line_items
    
    i.line_items_attributes=[{:id => '', :description => 'Created line item' }, {:description => 'Second created line item'}]

    #virtual attribute does not save
    assert_equal 0, i.line_items.count
    assert_equal 2, i.line_items.length
    
    assert i.save
    
    saved = Invoice.find(invoices(:invoice_with_no_line_items).id)
    assert_equal 2, saved.line_items.count
    assert_not_nil saved.line_items.find(:first, :conditions => {:description => 'Created line item'} )
    assert_not_nil saved.line_items.find(:first, :conditions => {:description => 'Second created line item'} )
  end
  
  def test_should_line_items_attributes_from_params
    i = Invoice.find(invoices(:invoice_with_line_items).id)
    
    assert_equal 2, i.line_items.length
    
    i.line_items_attributes=[{:id => line_items(:line_item_one).id, :description => 'Changed first line item' }, {:id => line_items(:line_item_two).id, :description=> 'Changed second line item'}]

    assert_equal 2, i.line_items.length
    assert i.save
    assert_equal 2, i.line_items.count
    
    saved = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal 2, saved.line_items.count
    assert_equal 'Changed first line item', saved.line_items.find(line_items(:line_item_one).id).description
    assert_equal 'Changed second line item', saved.line_items.find(line_items(:line_item_two).id).description
    
  end
  
  
  def test_should_remove_and_add_line_items_based_on_params
    i = Invoice.find(invoices(:invoice_with_no_line_items).id)
    id1 = i.line_items.create(:description => 'one', :position => 1).id
    id2 = i.line_items.create(:description => 'two', :position => 2).id
    id3 = i.line_items.create(:description => 'three', :position => 3).id
    
    i.line_items_attributes = [{:id => id2, :should_destroy => 1}, {:description => 'four'}, {:id => id1, :description => "one again"}]

    i.save
        
    assert_equal 3, i.line_items.count
    assert i.line_items.detect{|l| l.description == 'four'}
    assert i.line_items.detect{|l| l.description == 'one again'}
    assert_nil i.line_items.detect{|l| l.description == 'one'}
    assert_nil i.line_items.detect{|l| l.description == 'two'}
    
  end
  
  def test_should_fail_to_update_non_existent_line_item
    i = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_difference('i.line_items.count', -1) do
      li = i.line_items.detect {|l| l.id == line_items(:line_item_one).id}
      li.unit = 'Changed unit'
      
      # independently locate and delete the line item before saving the invoice
      li_to_delete = LineItem.find(line_items(:line_item_one))
      li_to_delete.destroy
      
      i.save
    end 
    
    i.reload
    assert_nil i.line_items.detect {|l| l.unit == 'Changed unit'}
  end
  
  def test_should_prune_ending_blank_line_items_from_params
    i = Invoice.find(invoices(:invoice_with_no_line_items).id)
    
    assert_equal 0, i.line_items.length
    
    i.line_items_attributes=[
      {:id => '', :description => 'Created line item' }, 
      {:unit => "", :description => "", :quantity => "", :price => ""},      
      {:description => 'Third created line item'},
      {:unit => "", :description => "", :quantity => "", :price => ""}
      ]

    #virtual attribute does not save
    assert_equal 0, i.line_items.count
    assert_equal 4, i.line_items.length
    
    assert i.save
    i.prune_empty_ending_line_items(true)
    
    saved = Invoice.find(invoices(:invoice_with_no_line_items).id)
    assert_equal 3, saved.line_items.count
    assert_not_nil saved.line_items.find(:first, :conditions => {:description => 'Created line item'} )
    assert_not_nil saved.line_items.find(:first, :conditions => {:description => 'Third created line item'} )
  end


    ##############  User Story 15/16 ####################################
  def test_should_set_invoice_state_to_sent_on_send_event
    u=users(:user_without_invoices)

    i = u.invoices.create(valid_invoice) #RADAR: this test will fail if we use Invoice.new instead of Invoice.create, as 
                       # the first event will not fire correctly
    deny i.sendable?
    i.line_items.create(valid_line_item)
    i.calculate_discounted_total
    i.customer=u.customers.create(valid_customer)
    i.save
    
    deny i.sendable?
    u = attach_valid_profile(u)
    i.created_by = u
    assert i.sendable?
    
    assert i.draft?, "invoice starts out as a draft"
    i.deliver!
    assert i.sent?
  end
  

  def test_sent_invoice_should_become_changed
    u=users(:user_without_invoices)
    u = attach_valid_profile(u)
    i = u.invoices.create(valid_invoice)
    deny i.sendable?
    i.line_items.create(valid_line_item)
    i.calculate_discounted_total
    i.customer=u.customers.create(valid_customer)
    i.save

    assert i.sendable?

    assert i.draft?, "invoice starts out as a draft"
    
    i.update_attributes(valid_invoice.merge(:description => "updating..."))
    
    assert i.draft?

    i.deliver!

    i.save_change!
    
    assert i.changed?
    
  end
  
  def test_should_return_default_contact_email_as_default_recipients
    invoices(:invoice_with_no_customer).save
    invoices(:invoice_with_customer_with_no_contacts).save
    invoices(:invoice_with_customer_with_contact).save

    assert_nil invoices(:invoice_with_no_customer).default_recipients, "invoice with no customer should return nil for default recipient"
    assert_nil invoices(:invoice_with_customer_with_no_contacts).default_recipients, "invoice with no customer should return nil for default recipient"
    assert_equal "basic_contact@contact-ville.com", invoices(:invoice_with_customer_with_contact).default_recipients
  end
  
  ##############  User Story 11 ####################################  
  
  
  def test_should_apply_discount_amount_to_reduce_total
    # invoice_with_line_items has 2 line items
    # line 1 { :quantity => 1.00, :price => 11.11 }
    # line 2 { :quantity => 2.00, :price => 22.22 }
    # invoice.line_item_total = 33.33
    # invoice.discount_amount = .66
    # invoice.total_amount = 32.67
    
    i = Invoice.find(invoices(:invoice_with_line_items))
    assert_not_nil i, "invoice with line items should not be nil"
    assert_equal BigDecimal.new("33.33"), i.line_items_total, "invoice line items total should be 33.33 before applying discount"
    
    i.discount_value = nil
    assert i.discount_string == ''
    
    i.discount_value = BigDecimal.new("0.66")
    i.discount_type = Invoice::AmountDiscountType

    i.save
    
    assert_equal BigDecimal.new("32.67"), i.total_amount, "invoice with line items total of 33.33 and a discount of .66 should have invoice total of 32.67. Actual total is #{i.total_amount} "
    
    
  end
  
  def test_should_apply_discount_type_amount
    i = Invoice.new
    i.unique = 98765
    i.currency = "USD"
    i.expects(:line_items_total).returns(100).at_least_once
    i.discount_value = 10

    i.discount_type = 'Bogus'
    assert_raises UnknownDiscountTypeException do
      i.calculate_discounted_total
    end

    i.discount_type = Invoice::AmountDiscountType
    assert i.save
    assert_equal 10, i.discount_amount
    assert_equal 90, i.total_amount.to_i
  end
  
  def test_should_apply_percent_type_amount

    i = Invoice.new
    i.unique = 98765
    i.currency = "USD"
    i.expects(:line_items_total).returns(200).at_least_once
    i.discount_value = 10
    i.discount_type = Invoice::PercentDiscountType
    assert i.save
    assert_equal 20, i.discount_amount
    assert_equal 180, i.total_amount.to_i
  end
  
  def test_should_check_discount_string
    # invoice_with_line_items has 2 line items
    # line 1 { :quantity => 1.00, :price => 11.11 }
    # line 2 { :quantity => 2.00, :price => 22.22 }
    # invoice.line_item_total = 33.33
    # invoice.discount_amount = .66
    # invoice.total_amount = 32.67
    
    i = Invoice.find(invoices(:invoice_with_line_items))
    assert_not_nil i, "invoice with line items should not be nil"
    assert_equal BigDecimal.new("33.33"), i.line_items_total, "invoice line items total should be 33.33 before applying discount"
    
    i.discount_value = BigDecimal.new("0.66")
    i.discount_type = Invoice::AmountDiscountType

    i.save
    assert_equal "$0.66", i.discount_string, "invoice discount string for amount is incorrect"
    
    i.discount_value = BigDecimal.new("2.12")
    i.discount_type = Invoice::PercentDiscountType

    i.save
    # a discount percent of 2.00 has a discount string of 2.0%, formatting needed?
    assert_equal "2.12%", i.discount_string, "invoice discount string for percent is incorrect"
    
  end
   
  ############### User story 14 #######################################
  # Unique invoice id (overridable), date, reference, and description field.

  def test_should_change_unique

    i = Invoice.find_by_unique(invoices(:invoice_with_unique_number).unique_number)
    assert i, "should find invoice with unique number"
    i2 = Invoice.find_by_unique(invoices(:invoice_with_unique_name).unique_name)
    assert i2, "should find invoice with unique name"
    assert_equal invoices(:invoice_with_unique_number).unique_number.to_s, i.unique, "should access unique attribute as number"

    
    i.unique = "Now a name"
    assert_equal true, i.save
    assert_equal "Now a name", i.unique, "should update unique attribute to a string name"
    assert_nil i.unique_number, "should update unique_number to be nil"
    
    i = Invoice.find(invoices(:invoice_with_unique_name).id)
    assert i, "should find invoice with unique name"
    assert_equal invoices(:invoice_with_unique_name).unique_name, i.unique, "should access unique attribute as string"
    assert_equal nil, i.unique_number, "should have nil unique_number"
    
    i.unique = 44
    assert_equal true, i.save
    assert_equal "44", i.unique, "should update unique attribute to a number"

  end

  ##############  User Story trac # 34 ####################################
  
  def test_should_get_tax_from_user
    u = User.new
#    Tax.expects(:new).returns(OpenStruct.new(:name=>'GST', :rate=>BigDecimal.new('6.00'), :included=>false, :taxed_on=>[]),
#                              OpenStruct.new(:name=>'PST', :rate=>BigDecimal.new('7.00'), :included=>false, :taxed_on=>[])).times(2)
    i = Invoice.new
    i.created_by = u
    i.expects(:taxes).returns([
      OpenStruct.new(:name=>'GST', :rate=>BigDecimal.new('6.00'), :included=>false, :taxed_on=>[]),
      OpenStruct.new(:name=>'PST', :rate=>BigDecimal.new('7.00'), :included=>false, :taxed_on=>[])
                              ]).once
    t1, t2 = i.taxes
    assert i.respond_to?(:taxes)
    assert_equal 'GST', t1.name
    assert_equal BigDecimal.new('6.00'), t1.rate
    assert_equal false, t1.included
    assert_equal [], t1.taxed_on
    assert_equal 'PST', t2.name
    assert_equal BigDecimal.new('7.00'), t2.rate
    assert_equal false, t2.included
    assert_equal [], t2.taxed_on
  end
  
  ############ For code coverage
  
  def test_should_calculate_and_retrieve_tax_amount
    u = User.new
    i = Invoice.new
    i.created_by = u
    assert_equal 0, i.line_items.length
    i.line_items_attributes=[{:id => '', :unit => "", :description => "", :quantity => "1", :price => "10"}]

    InvoiceCalculator.expects(:setup_for).returns(
       OpenStruct.new(:discount => BigDecimal.new('0'), :tax => BigDecimal.new('1.20'), :total => BigDecimal.new('11.20'))
    ).once

    assert_equal BigDecimal.new('1.20'), i.tax_amount
    #should not call InvoiceCalculator.setup_for again.
    assert_equal BigDecimal.new('1.20'), i.tax_amount
  end

  def test_should_calculate_invoice_total_for_tax_1_amount
    u = User.new
    i = Invoice.new
    i.created_by = u

    InvoiceCalculator.expects(:setup_for).returns(
       OpenStruct.new(:discount => BigDecimal.new('0'), :tax => BigDecimal.new('1.20'), :total => BigDecimal.new('11.20'))
    ).once
    
    i.stubs(:taxes).returns([
      OpenStruct.new(:key=>'tax_1', :name=>'GST', :rate=>BigDecimal.new('5.00'), :included=>false, :taxed_on=>[], :amount=>BigDecimal.new('0.50')),
      OpenStruct.new(:key=>'tax_2', :name=>'PST', :rate=>BigDecimal.new('7.00'), :included=>false, :taxed_on=>[], :amount=>BigDecimal.new('0.70'))
                              ]).at_least_once

    i.tax_1_amount
    #should not call InvoiceCalculator.setup_for again.
    i.tax_1_amount
  end

  def test_should_calculate_invoice_total_for_tax_2_amount
    u = User.new
    i = Invoice.new
    i.created_by = u

    InvoiceCalculator.expects(:setup_for).returns(
       OpenStruct.new(:discount => BigDecimal.new('0'), :tax => BigDecimal.new('1.20'), :total => BigDecimal.new('11.20'))
    ).once
    
    i.stubs(:taxes).returns([
      OpenStruct.new(:key=>'tax_1', :name=>'GST', :rate=>BigDecimal.new('5.00'), :included=>false, :taxed_on=>[], :amount=>BigDecimal.new('0.50')),
      OpenStruct.new(:key=>'tax_2', :name=>'PST', :rate=>BigDecimal.new('7.00'), :included=>false, :taxed_on=>[], :amount=>BigDecimal.new('0.70'))
                              ]).at_least_once

    i.tax_2_amount
    #should not call InvoiceCalculator.setup_for again.
    i.tax_2_amount
  end

  def test_same_invoice_should_create_same_access_key
    i=invoices(:invoice_with_unique_name)
    ak_1 = i.get_or_create_access_key
    ak_2 = i.get_or_create_access_key
    assert_equal ak_1, ak_2
  end
  
  def test_should_create_unique_access_key_with_different_invoices
    i1, i2 = invoices(:invoice_with_unique_name, :draft_invoice)
    ak_1 = i1.get_or_create_access_key
    ak_2 = i2.get_or_create_access_key
    assert ak_1 != ak_2
  end
  
  def test_should_be_fully_paid_if_amount_owing_is_0
    i = Invoice.new
    i.expects(:amount_owing).returns(BigDecimal.new("0"))
    assert i.fully_paid?
    i.expects(:amount_owing).returns(BigDecimal.new("0.1"))
    deny i.fully_paid?
  end
  
  def test_description_returns_invoice_unique_if_nil
    i=Invoice.new
    i.description = nil
    i.unique_name = 'bob'
    assert_equal 'Invoice: bob', i.description
    i.description = "cool invoice"
    assert_equal 'cool invoice', i.description
  end
  
  def test_invoice_should_return_total_as_cents
    i=Invoice.new
    i.expects(:total_amount).returns(BigDecimal.new('11.37'))
    assert_equal 1137, i.total_as_cents
  end
  
  def test_invoice_should_return_total_taxes_as_cents
    i=Invoice.new
    i.expects(:total_taxes).returns(BigDecimal.new('2.11'))
    assert_equal 211, i.total_taxes_as_cents
  end

  def test_invoice_should_return_total_taxes_as_cents_from_float
    i=Invoice.new
    i.expects(:total_taxes).returns(2.11)
    assert_equal 211, i.total_taxes_as_cents
  end

  def should_return_customer_name
    i = Invoice.new
    assert_nil i.customer_name
    i.build_customer(:name => 'bob')
    assert_equal 'bob', i.customer_name
  end



  ############### filtered_invoices tests -- duplicated from invoices_controller tests, to have full coverage in unit tests ###################
  
  def test_should_find_invoice_by_unique_number   
     # ask for invoice with unique number 2
    filters = OpenStruct.new({:unique=>"2"})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:heavy_user).invoices, filters)
     assert_equal 1, invoices.length, "there should only be one invoice"
     assert_equal "2", invoices.first.unique_number.to_s
   end

  def test_should_find_invoices_for_multiple_customers
    filters = OpenStruct.new({:customers=> [customers(:heavy_user_customer_2).id, customers(:heavy_user_customer_3).id]})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:heavy_user).invoices, filters)
    assert_equal 6, invoices.size
    assert invoices.any?{|i| i.customer == customers(:heavy_user_customer_2)}    
    assert invoices.any?{|i| i.customer == customers(:heavy_user_customer_3)}    
    assert invoices.all?{|i| i.customer == customers(:heavy_user_customer_2) || i.customer == customers(:heavy_user_customer_3)}    
  end

  def test_should_find_draft_invoices
    filters = OpenStruct.new({:statuses => ['draft'], :customers => "#{customers(:customer_with_every_status_invoice).id}"})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    assert_equal 1, invoices.size
    assert invoices.all?{|i| i.draft?}        
  end

  def test_should_find_sent_invoices
    filters = OpenStruct.new({:statuses => ['sent'], :customers => "#{customers(:customer_with_every_status_invoice).id}"})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    assert_equal 2, invoices.size
    assert invoices.all?{|i| i.sent? or i.resent?}        
  end

  def test_should_find_unsent_invoices 
    filters = OpenStruct.new({:statuses => ['unsent'], :customers => "#{customers(:customer_with_every_status_invoice).id}"})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    assert_equal 2, invoices.size
    assert invoices.all?{|i| i.draft? or i.changed?}        
  end


  def test_should_find_paid_invoices
    filters = OpenStruct.new({:statuses => ['paid'], :customers => "#{customers(:customer_with_every_status_invoice).id}"})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    assert_equal 1, invoices.size
    assert invoices.all?{|i| i.paid?}        
  end

  def test_should_find_unpaid_invoices
    filters = OpenStruct.new({:statuses => ['unpaid'], :customers => "#{customers(:customer_with_every_status_invoice).id}"})
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    assert_equal 4, invoices.size
    assert invoices.all?{|i| !i.paid?}        
  end

  def test_should_find_by_meta_status_past_due

    filters = OpenStruct.new()

    filters.conditions = Invoice.find_by_meta_status_conditions(Invoice::META_STATUS_PAST_DUE)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 1, invoices.size
    invoices = invoices.to_a
    assert(invoices.first.due_date < (Date.today))
  end
  
  def test_should_find_by_meta_status_draft

    filters = OpenStruct.new()

    filters.conditions = Invoice.find_by_meta_status_conditions(Invoice::META_STATUS_DRAFT)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 19, invoices.size
    invoices = invoices.to_a
    assert invoices.all?{|i| i.draft?}        
  end
  
  def test_should_find_by_meta_status_outstanding

    filters = OpenStruct.new()

    filters.conditions = Invoice.find_by_meta_status_conditions(Invoice::META_STATUS_OUTSTANDING)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 2, invoices.size
    invoices = invoices.to_a
    assert invoices.all?{|i| i.sent? or i.resent? or i.changed? or i.acknowledged?}        
  end
  
  def test_should_find_by_meta_status_paid

    filters = OpenStruct.new()

    filters.conditions = Invoice.find_by_meta_status_conditions(Invoice::META_STATUS_PAID)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 1, invoices.size
    invoices = invoices.to_a
    assert invoices.all?{|i| i.paid?}        
  end
  
  def test_should_find_from_date
    filters = OpenStruct.new()
    setup_dated_invoices

    filters.fromdate = Date.today.to_s(:db)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 3, invoices.size

    filters.fromdate = (Date.today - 2.days).to_s(:db)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)

    assert_equal 6, invoices.size
    
  end
  
  def test_should_find_to_date
    filters = OpenStruct.new()
    setup_dated_invoices

    filters.todate = Date.today.to_s(:db)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 3, invoices.size

    filters.todate = (Date.today - 2.days - 1.hour).to_s(:db)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)

    assert_equal 0, invoices.size
    
  end
  
  def test_should_find_between_dates
    filters = OpenStruct.new()
    setup_dated_invoices

    filters.fromdate = Date.today.to_s(:db)
    filters.todate = (Date.today + 1.day + 1.hour).to_s(:db)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    
    assert_equal 2, invoices.size

    filters.fromdate = (Date.today - 2.days).to_s(:db)
    filters.todate = (Date.today + 4.days).to_s(:db)
    filters.page = {:page => 0, :size => 10}
    invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)

    assert_equal 6, invoices.size
    
  end
  
  
  def test_should_filter_invoices_by_type
    filters = OpenStruct.new()
    user = users(:simply_accounting_user)

    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 3, invoices.length
    
    filters.invoice_type = 'Invoice'
    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 1, invoices.length

    filters.invoice_type = 'SimplyAccountingInvoice'
    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 2, invoices.length
  end
  
  def test_should_filter_invoices_by_currency
    filters = OpenStruct.new()
    user = users(:simply_accounting_user)

    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 3, invoices.length
    
    filters.currency = 'ZAR'
    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 1, invoices.length
  end
  
  def test_should_fallback_to_first_currency
    filters = OpenStruct.new()
    user = users(:simply_accounting_user)

    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 3, invoices.length
    
    filters.currency = 'JPY'
    invoices = Invoice.filtered_invoices(user.invoices, filters)    
    assert_equal 2, invoices.length
  end
  
  def test_should_return_currency_string
    #TODO
    assert_equal "$100.00", Invoice.new.currency_string(BigDecimal.new('100.00'))
  end
  
  def test_should_return_overview_listing_json_params
    # this just makes sure the method isn't broken, does not test what values are in it
    assert Invoice.overview_listing_json_params.is_a?(Hash)
  end
  
  def test_should_return_json_for_overview
    json = invoices(:draft_invoice).to_json(Invoice.overview_listing_json_params)
    as_hash = ActiveSupport::JSON.decode(json)
    
    assert_equal 'draft', as_hash["status"]
    deny invoices(:draft_invoice).customer.name.blank?
    assert_equal invoices(:draft_invoice).customer.name, as_hash["customer_name"]
    assert_equal invoices(:draft_invoice).customer_id, as_hash["customer_id"]
    assert_equal 0.0, as_hash["total_amount"]
    assert_equal 0.0, as_hash["amount_owing"]
    assert_equal 'invoice', as_hash["invoice_type_for_css"]
    assert_equal invoices(:draft_invoice).id, as_hash["id"]
  end
  
  def test_should_return_status_filters
    # this just makes sure the method isn't broken, does not test all values are in it
    assert Invoice.status_filters.is_a?(Array)
    assert_equal 'draft', Invoice.status_filters.first.value
    assert_equal 'Draft', Invoice.status_filters.first.name
  end
  
  def test_should_return_customer_name
    assert_nil invoices(:invoice_with_no_customer).customer_name
    assert_equal 'Customer with no contacts', invoices(:invoice_with_no_profile).customer_name
  end

  ######## Trac #92: Update invoice total when line item is deleted
  def test_should_exclude_should_destroy_line_items_from_total
    i = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal BigDecimal.new('33.33'), i.line_items_total
    
    i.line_items[0].should_destroy=1
    
    assert_equal BigDecimal.new('22.22'), i.line_items_total
  end

  ######## Trac #94: Invoice screen should not allow negative tax rates
  def test_should_not_allow_negative_tax_rate
    i = Invoice.find(invoices(:invoice_with_customer_with_no_contacts).id)
    i.tax_1_rate = 1
    i.tax_2_rate = 1
    # deny i.valid?, 'Invoice should fail to save with positive tax rate but no tax name.' #this now handled by clean_up_taxes. 
    i.tax_1_name = "bob"
    i.tax_2_name = "mary"
    i.tax_1_rate = 1
    i.tax_2_rate = 1
    assert i.valid?, 'Invoice should save with positive tax rate and tax name.'

    i.tax_1_rate = -1
    deny i.valid?, 'Invoice should not save with negative tax rate.'

    i.tax_1_rate = 1
    i.tax_2_rate = -1
    deny i.valid?, 'Invoice should not save with negative tax rate.'
  end
  
  
  def test_should_save_after_destroying_line_items
    assert_nothing_raised do
      u=users(:user_without_invoices)
      i = u.invoices.build(valid_invoice)
      i.line_items_attributes=[{:id => '', :description => 'Created line item' }, {:description => 'Second created line item'}]
      assert i.save
      
      i.line_items.first.destroy
      i.save
    end
  end
  
  #This test is no longer relevant as invoice date is now set in the controller as it needs to be timezone aware
  #and timezone information is only available when in the controller
 # def test_should_set_default_invoice_date
 #   i = Invoice.new(valid_invoice(:unique => "98765" ))
 #   i.prepare_default_fields
 #   i.save
 #   assert_equal Date.today, i.date
 # end
 
  def test_should_allow_override_of_default_date
    i = Invoice.new(valid_invoice(:unique => "98765" ))
    i.prepare_default_fields
    i.date = Date.today + 2
    i.save
    assert_equal((Date.today + 2), i.date)
  end
  
  def test_should_allow_blank_date_at_save
    i = Invoice.new(valid_invoice(:unique => "98765" ))
    i.prepare_default_fields
    i.date = ""
    i.save
    assert_equal nil, i.date    
  end
  
  def test_should_disallow_due_date_before_date
    i = Invoice.find(invoices(:invoice_with_due_date_before_date))
    assert_equal false, i.save, 'Invoice should not save with due date before issue date.'
  end
  
  def test_should_save_invoice_with_other_date_combinations
    i1 = Invoice.find(invoices(:invoice_draft_11th))
    i2 = Invoice.find(invoices(:invoice_with_date_and_due_date))
    i3 = Invoice.find(invoices(:invoice_with_line_items))
    i4 = Invoice.find(invoices(:invoice_with_due_date_and_no_date))
    
    assert_equal true, i1.save, 'Invoice with no date and no due date should save'
    assert_equal true, i2.save, 'Invoice with date and later due date should save'
    assert_equal true, i3.save, 'Invoice with date and no due date should save'
    assert_equal true, i4.save, 'Invoice with due date and no date should save'
  end
  
  
  def test_should_have_description_for_paypal_less_than_128_chars
    i = Invoice.find(invoices(:invoice_with_date_and_due_date))
    i.unique_name = "this_unique_is_much_too_long_to_fit_in_the_paypal_description"
    i.send(:unique_number=, nil)
    assert_equal 128, i.description_for_paypal.length
    i.send(:unique_name=, nil)
    i.send(:unique_number=, 6)
    assert i.description_for_paypal.length < 128
  end
  
  
  ######## Trac #126 -- unique numbering
  def test_should_consider_negative_number_as_custom
    delete_invoices
    i = Invoice.new(valid_invoice(:unique => -1 ))
    
    assert_equal "-1", i.unique
    assert_equal "name", i.unique_type 
  end
  

  def test_should_consider_zero_number_as_custom
    delete_invoices
    i = Invoice.new(valid_invoice(:unique => 0 ))
    
    assert_valid i
    assert_equal "0", i.unique
    assert_equal "name", i.unique_type 

    i = Invoice.new(valid_invoice(:unique => "00" ))
    
    assert_valid i
    assert_equal "00", i.unique
    assert_equal "name", i.unique_type 

    i = Invoice.new(valid_invoice(:unique => "01" ))
    
    assert_valid i
    assert_equal "01", i.unique
    assert_equal "name", i.unique_type 
  end
  
  def test_should_consider_non_number_as_custom
    delete_invoices
    i = Invoice.new(valid_invoice(:unique => 'a123' ))
    
    assert_valid i
    assert_equal "a123", i.unique
    assert_equal "name", i.unique_type 
  end
  
  def test_should_refuse_to_save_duplicate_number_invoice
    delete_invoices
    i = valid_invoice_obj(true, :unique => 123)
    i2 = valid_invoice_obj(false, :unique => 123)
    assert_not_valid i2
    i2.unique = 124
    assert_valid i2
  end
  
  def test_should_refuse_to_save_duplicate_name_invoice
    delete_invoices
    i = valid_invoice_obj(true, :unique => 'abc')
    i2 = valid_invoice_obj(false, :unique => 'abc')
    assert_not_valid i2
    i2.unique = 'abd'
    assert_valid i2
  end
  
  def test_should_set_first_auto_as_one
    delete_invoices
    i = valid_invoice_obj(false)
    i.unique = i.created_by.generate_next_auto_number
    assert_equal "1", i.unique
    assert_valid i
  end

  def test_should_set_second_auto_as_two
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 1)
    i2 = valid_invoice_obj(false)    
    i2.unique = i2.generate_next_auto_number 
    assert_equal "2" , i2.unique
    assert_valid i2
  end

  def test_custom_number_should_not_interrupt_count
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 1)
    i2 = valid_invoice_obj(true, :unique => -1)
    i3 = valid_invoice_obj(false)  
    i3.unique = i3.generate_next_auto_number
    assert_equal "2", i3.unique
    assert_valid i3
  end  
  
  def test_nonsequential_auto_is_accepted
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 1)
    i2 = valid_invoice_obj(false, :unique => 5)
    assert_valid i2
  end

  def test_proper_incrementation_after_highest
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 5)
    i2 = valid_invoice_obj(false)
    i2.unique = i2.generate_next_auto_number
    assert_equal "6", i2.unique
    assert_valid i2
  end

  def test_proper_incrementation_after_lower_with_one_gap
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 5)
    i2 = valid_invoice_obj(true, :unique => 3)
    i3 = valid_invoice_obj(false)
    i3.unique = i3.generate_next_auto_number
    assert_equal "4", i3.unique
    assert_valid i3
  end
  
  def test_proper_incrementation_after_lower_with_two_gaps
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 6)
    i2 = valid_invoice_obj(true, :unique => 3)
    i3 = valid_invoice_obj(false)
    i3.unique = i3.generate_next_auto_number
    assert_equal "4", i3.unique
    assert_valid i3
  end

  def test_proper_incrementation_after_multiple_tries
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 5)
    i2 = valid_invoice_obj(true, :unique => 6)
    i3 = valid_invoice_obj(true, :unique => 7)
    i4 = valid_invoice_obj(false)
    i4.unique = i4.generate_next_auto_number
    assert_equal "8", i4.unique
    assert_valid i4
  end
  
  def test_custom_scoping
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => 1, :created_by => users(:basic_user))
    i2 = valid_invoice_obj(false, :unique => 1)
    assert_valid i2
  end
  
  def test_auto_scoping
    delete_invoices
    i1 = valid_invoice_obj(true, :unique => "asdfasdf", :created_by => users(:basic_user))
    i2 = valid_invoice_obj(false, :unique => "asdfasdf")
    assert_valid i2    
  end
  
  def test_unique_for_paypal
    i = Invoice.new
    assert i.unique_for_paypal.blank?
    i.unique = "test"
    assert_equal('test', i.unique_for_paypal)
    i.unique = ("bob" * 80)
    i.expects(:id).at_least_once.returns(1764)
    assert_equal(120, i.unique_for_paypal.length)
    assert_match(/1764/, i.unique_for_paypal)
  end
  
  def test_should_get_payment_gateway_credentials_from_user_profile
    i=Invoice.new
    i.expects(:user_gateway).with('paypal_express').returns(PaypalExpressUserGateway.new(:gateway_name => 'paypal_express', :user_id => 1, :email => 'a@b.com'))
    assert_equal({ :email => 'a@b.com' }, i.payment_gateway_credentials('paypal_express'))
  end
  
  def test_should_has_line_items
    i = valid_invoice_obj(true)
    assert !i.has_line_items?
    i.line_items.build(valid_line_item)
    i.save!
    assert i.has_line_items?
  end

  def test_should_reject_over_a_million
    i = valid_invoice_obj
    i.line_items.build({:price => BigDecimal.new("125000"), :quantity => 8})
    assert_not_valid i
    i.line_items.first.price = BigDecimal.new("124999")
    i.calculate_discounted_total
    assert_valid i
    
  end

  def test_wanted_unique
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    assert_equal true, i.unique_available?
    
    i.save
    i2 = Invoice.new(valid_invoice(:unique => 98765 ))
    assert_equal "98766", i2.unique_available?
  end

  def test_auto_unique
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    i.unique = "asdf"
    assert_equal false, i.unique_auto?
    i.unique = "0"
    assert_equal false, i.unique_auto? 
    i.unique = "00"
    assert_equal false, i.unique_auto? 
    i.unique = "01"
    assert_equal false, i.unique_auto?
    i.unique = "-0.1"
    assert_equal false, i.unique_auto? 
    i.unique = "-1"
    assert_equal false, i.unique_auto?
    i.unique = "1"
    assert_equal true, i.unique_auto? 
  end
  
  def test_currency_saves
    u = users(:user_without_invoices)
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    assert_equal "USD", i.currency
    i.currency = "CAD"
    i.save!

    assert_equal "CAD", i.currency  
  end
  
  def test_remembers_last_currency
    u = users(:user_without_invoices)
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    i.save!
    assert_equal "USD", i.currency
    
    i2 = Invoice.new(valid_invoice(:unique => 98766 ))
    i2.currency = "GBP"
    i2.save!
    assert_equal "GBP", i2.currency    

    i3 = Invoice.new(valid_invoice(:unique => 98767 ))
    i3.currency = nil
    i3.save!
    assert_equal "GBP", i3.currency 
    
  end
  
  def test_currency_updates_profile
    u = users(:user_without_invoices)
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    i.currency = "CAD"
    i.save!

    assert_equal "CAD", u.profile.currency
    u.profile.reload
    assert_equal "CAD", u.profile.currency
  end
  
  def test_calculate_discount_called_on_nil_total
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    i.save
    i.total_amount = nil
    assert_equal nil, i.read_attribute('total_amount')
    i.expects(:calculate_discounted_total)
    i.total_amount
  end
  
  def test_reject_negative_discount
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    i.discount_amount = -10
    deny i.valid?
    i.discount_amount = 10
    assert i.valid?
  end
  
  def test_meta_status_is_proper
    i = Invoice.new(valid_invoice(:unique => 98765 ))
    i.due_date = nil
    i.status = "draft"
    assert_equal i.meta_status_string, "Draft Invoice"
    assert_equal i.brief_meta_status_string, "Draft"
    
    i.status = "printed"
    assert_equal i.meta_status_string, "Draft Invoice"
    assert_equal i.brief_meta_status_string, "Draft"
    
    i.status = "sent"
    assert_equal i.meta_status_string, "Outstanding Invoice"
    assert_equal i.brief_meta_status_string, "Outstanding"
    
    i.status = "resent"
    assert_equal i.meta_status_string, "Outstanding Invoice"
    assert_equal i.brief_meta_status_string, "Outstanding"
    
    i.status = "changed"
    assert_equal i.meta_status_string, "Outstanding Invoice"
    assert_equal i.brief_meta_status_string, "Outstanding"
    
    i.status = "acknowledged"
    assert_equal i.meta_status_string, "Outstanding Invoice"
    assert_equal i.brief_meta_status_string, "Outstanding"

    i.status = "paid"
    assert_equal i.meta_status_string, "Paid Invoice"
    assert_equal i.brief_meta_status_string, "Paid"
    
    #check for past due
    
    i.due_date = Date.today
    i.status = "sent"
    assert_equal i.meta_status_string, "Past Due Invoice"
    assert_equal i.brief_meta_status_string, "Past Due"
    
    i.status = "resent"
    assert_equal i.meta_status_string, "Past Due Invoice"
    assert_equal i.brief_meta_status_string, "Past Due"
    
    i.status = "changed"
    assert_equal i.meta_status_string, "Past Due Invoice"
    assert_equal i.brief_meta_status_string, "Past Due"
    
    i.status = "acknowledged"
    assert_equal i.meta_status_string, "Past Due Invoice"
    assert_equal i.brief_meta_status_string, "Past Due"
    
  end
  
  def test_url_for_gateway
    invoice = Invoice.new
    invoice.expects(:create_access_key).returns('123')
    invoice.stubs(:user_gateway).returns(BeanStreamUserGateway.new(:gateway_name => 'beanstream'))
    assert_equal "http://#{host_for_test}/invoices/123/online_payments/beanstream", invoice.url_for_gateway('beanstream')
  end
  
  def test_url_for_gateway_uses_secure_host
    invoice = Invoice.new
    invoice.expects(:create_access_key).returns('123')
    ::AppConfig.stubs(:use_ssl).returns(true)
    ::AppConfig.stubs(:mail).returns(OpenStruct.new(:secure_host => 'https://bob.com'))
    invoice.stubs(:user_gateway).returns(BeanStreamUserGateway.new(:gateway_name => 'beanstream'))
    assert_equal 'https://bob.com/invoices/123/online_payments/beanstream', invoice.url_for_gateway('beanstream')
  end

  def test_using_gateways
    i = Invoice.new(:currency => 'CAD')
    user = mock('user')
    i.stubs(:created_by).returns(user)
    i.expects(:selected_payment_types).returns([:paypal, :visa])
    paypal = PaypalUserGateway.new
    paypal.expects(:handle_invoice?).with(i).returns(true)
    sage = SageSbsUserGateway.new(:currency => 'USD')
    sage.expects(:handle_invoice?).with(i).returns(false)
    user.expects(:user_gateways_for).with('CAD', [:paypal, :visa]).returns([paypal, sage])
    assert_equal [paypal], i.using_user_gateways
  end

  def attach_valid_profile(user)
    user.profile.heard_from = "Banks"
    user.profile.company_name = "Test Company"
    user.profile.company_address1 = "Test Address 1"
    user.profile.company_city = "Test City"
    user.profile.company_country = "Canada"
    user.profile.company_state = "British Columbia"
    user.profile.company_postalcode = "V1V 1V1"
    user.profile.company_phone = "123 456 7890"
    user.profile.save!
    user.save!
    return user
  end

  def test_default_payment_types_for_currency_first_time
    user = mock('user')
    user.stubs(:invoices).returns(mock('invoices'))
    user.expects(:payment_types).with('CAD').returns([:visa, :master, :american_express])
    user.invoices.expects(:find_last_by_currency).with('CAD').returns(nil)
    assert_equal [:visa, :master, :american_express], Invoice.default_payment_types(user, 'CAD')
  end

  def test_default_payment_types_for_currency
    user = mock('user')
    user.stubs(:invoices).returns(mock('invoices'))
    user.expects(:payment_types).with('CAD').returns([:visa, :master, :american_express])
    invoice = Invoice.new(:currency => 'CAD')
    invoice.stubs(:created_by).returns(user)
    invoice.expects(:payment_types).returns([:visa, :american_express, :discover])
    user.invoices.expects(:find_last_by_currency).with('CAD').returns(invoice)
    assert_equal [:visa, :american_express], Invoice.default_payment_types(user, 'CAD')
  end

  def test_invoice_payment_types_strings
    i = Invoice.new
    i.payment_types = ['visa', 'master']
    assert_equal('visa,master', i['payment_types'])
    assert_equal([:visa, :master], i.payment_types)
  end

  def test_invoice_payment_types
    i = Invoice.new
    i.payment_types = [:visa, :master]
    assert_equal('visa,master', i['payment_types'])
    assert_equal([:visa, :master], i.payment_types)
  end

  def test_invoice_payment_types_empty
    i = Invoice.new
    i.payment_types = []
    assert_equal(nil, i['payment_types'])
    assert_equal([], i.payment_types)
  end

  def test_all_payment_types_nil
    i = Invoice.new
    assert_equal [], i.all_payment_types
  end

  def test_all_payment_types_normal
    i = Invoice.new
    user = mock('user')
    i.stubs(:created_by).returns(user)
    i.currency = 'CAD'
    user.expects(:payment_types).with('CAD').returns([:visa])
    assert_equal [:visa], i.all_payment_types
  end

  def test_selected_payment_types
    i = Invoice.new
    i.expects(:payment_types).returns([:visa, :master])
    i.expects(:all_payment_types).returns([:paypal, :visa])
    assert_equal [:visa], i.selected_payment_types
  end

  def test_is_selected_payment_type
    i = Invoice.new
    i.expects(:selected_payment_types).times(2).returns([:visa, :paypal])
    assert i.selected_payment_type?(:visa)
    deny i.selected_payment_type?(:master)
  end

  def test_find_last_by_currency_not_found
    assert_nil Invoice.find_last_by_currency('XYZ')
  end

  def test_find_last_by_currency_multiple
    Invoice.update_all(['currency = \'CAD\', updated_at = ?', Time.now + 100], 'id = 77')
    Invoice.update_all(['currency = \'USD\', updated_at = ?', Time.now + 200], 'id = 76')
    i = Invoice.find(77)
    assert_equal i, Invoice.find_last_by_currency('CAD')
  end

  def test_delivering
    d = Delivery.new
    d.mail_options = { 'payment_types' => ['paypal', 'visa'] }
    i = Invoice.new
    i.expects(:payment_types=).with(['paypal', 'visa'])
    i.delivering(d)
  end
  
  def test_gst
    gst = Tax.new(:rate => 1, :name => 'gst', :amount => 10)
    pst = Tax.new(:rate => 1, :name => 'pst', :amount => 5)
    i = Invoice.new
    i.taxes << gst
    i.taxes << pst
    assert_equal 10, i.gst
  end
 
  def test_pst
    gst = Tax.new(:rate => 1, :name => 'gst', :amount => 10)
    pst = Tax.new(:rate => 1, :name => 'pst', :amount => 5)
    i = Invoice.new
    i.taxes << gst
    i.taxes << pst
    assert_equal 5, i.pst
  end
  
  def test_total_taxes
    gst = Tax.new(:rate => 1, :name => 'gst', :amount => 10)
    pst = Tax.new(:rate => 1, :name => 'pst')
    i = Invoice.new
    i.taxes << gst
    i.taxes << pst
    assert_equal 10, i.total_taxes
  end

  def test_should_clear_contact_when_customer_changes_issue_738
    user = users(:basic_user)
    customer = add_valid_customer(user, {:name => 'OriginalCustomer', :contacts => nil})
    assert_equal 'OriginalCustomer', customer.name
    
    invoice = add_valid_invoice(user, {:customer => customer, :contact_attributes => {:first_name => 'Original', :last_name => 'Contact'}})

    invoice = Invoice.find(invoice.id)
    assert_equal 'OriginalCustomer', invoice.customer.name
    assert_equal 'Original Contact', invoice.contact.name
    assert_equal 'Original Contact', invoice.customer.contact.name
    
    customer = add_valid_customer(user, {:name => 'NewCustomer', :contacts => nil})
    invoice.customer = customer
    invoice.save

    assert_equal 'NewCustomer', invoice.customer.name
    assert_nil invoice.contact
    
  end
  
  def test_unsaved_invoice_and_line_items_tax_calculation
    u=users(:complete_user)
    i = u.invoices.new
    gst = Tax.new(:rate => 1, :name => 'gst', :profile_key => "tax_1")
    pst = Tax.new(:rate => 2, :name => 'pst', :profile_key => "tax_2")
    i.taxes << gst
    i.taxes << pst
    li = i.line_items.new
    li.price = 100
    li.quantity = 1
    i.line_items = [li]
    assert_equal 1, i.tax_1_amount
    li.tax_1_enabled = false
    i.calculate_discounted_total
    assert_equal 0, i.tax_1_amount
    
  end
  
  def test_saved_invoice_and_line_items_tax_calculation
    u=users(:complete_user)
    i = u.invoices.new
    gst = Tax.new(:rate => 1, :name => 'gst', :profile_key => "tax_1")
    pst = Tax.new(:rate => 2, :name => 'pst', :profile_key => "tax_2")
    i.taxes << gst
    i.taxes << pst
    li = i.line_items.new
    li.price = 100
    li.quantity = 1
    i.line_items = [li]
    li.save!
    i.save!
    assert_equal 1, i.tax_1_amount
    li.tax_1_enabled = false
    li.save!
    i.save!
    i.calculate_discounted_total
    assert_equal 0, i.tax_1_amount    
  end
  
  def test_two_line_items_with_one_having_two_taxes_and_one_having_one_tax_calculation

    u=users(:complete_user)
    i = u.invoices.new
    gst = Tax.new(:rate => 1, :name => 'gst', :profile_key => "tax_1")
    pst = Tax.new(:rate => 2, :name => 'pst', :profile_key => "tax_2")
    i.taxes << gst
    i.taxes << pst
    li1 = i.line_items.new
    li2 = i.line_items.new
    li1.price = 100
    li1.quantity = 1
    li2.price = 200
    li2.quantity = 1
    i.line_items = [li1, li2]
    assert_equal 3, i.tax_1_amount
    assert_equal 6, i.tax_2_amount
    li1.tax_1_enabled = false
    i.calculate_discounted_total
    assert_equal 2, i.tax_1_amount
    assert_equal 6, i.tax_2_amount
    
  end
  
  def test_two_line_items_with_alternating_taxes_enabled_calculatinon
    u=users(:complete_user)
    i = u.invoices.new
    gst = Tax.new(:rate => 1, :name => 'gst', :profile_key => "tax_1")
    pst = Tax.new(:rate => 2, :name => 'pst', :profile_key => "tax_2")
    i.taxes << gst
    i.taxes << pst
    li1 = i.line_items.new
    li2 = i.line_items.new
    li1.price = 100
    li1.quantity = 1
    li2.price = 200
    li2.quantity = 1
    i.line_items = [li1, li2]
    assert_equal 3, i.tax_1_amount
    assert_equal 6, i.tax_2_amount
    li1.tax_1_enabled = false
    li2.tax_2_enabled = false
    i.calculate_discounted_total
    assert_equal 2, i.tax_1_amount
    assert_equal 2, i.tax_2_amount    
  end
  
  def test_disabled_line_items_taxes
    u=users(:complete_user)
    i = u.invoices.new
    gst = Tax.new(:rate => 1, :name => 'gst', :profile_key => "tax_1")
    pst = Tax.new(:rate => 2, :name => 'pst', :profile_key => "tax_2")
    i.taxes << gst
    i.taxes << pst
    li = i.line_items.new
    li.price = 100
    li.quantity = 1
    i.line_items = [li]
    assert_equal 1, i.tax_1_amount
    li.tax_1_enabled = false
    li.tax_2_enabled = false
    i.calculate_discounted_total
    assert_equal 0, i.tax_1_amount
    assert_equal 0, i.tax_2_amount
  end

  def test_by_default_line_items_have_both_taxes_enabled
    u=users(:complete_user)
    i = u.invoices.new
    gst = Tax.new(:rate => 1, :name => 'gst', :profile_key => "tax_1")
    pst = Tax.new(:rate => 2, :name => 'pst', :profile_key => "tax_2")
    i.taxes << gst
    i.taxes << pst
    li = i.line_items.new
    li.price = 100
    li.quantity = 1
    li.save!
    i.line_items = [li]
    i.save!
    assert li.tax_1_enabled?
    assert li.tax_2_enabled?
  end
  
  def test_disallow_editing_an_invoice_that_would_produce_negative_amount_owing
    u=users(:basic_user)
    i = invoices(:sent_invoice)
    i.expects(:paid).returns(BigDecimal.new("20")).at_least_once
    deny i.valid?
    i.expects(:paid).returns(BigDecimal.new("5")).at_least_once
    assert i.valid?
  end

  def test_quotes_should_have_separate_numbers
    u=users(:basic_user)
    delete_invoices
    invoice = u.invoices.create
    quote = u.invoices.create and quote.save_quote!

    assert_equal 1, invoice.unique.to_i
    assert_equal 1, quote.unique.to_i

    quote = u.invoices.create and quote.save_quote!
    invoice = u.invoices.create

    assert_equal 2, invoice.unique.to_i
    assert_equal 2, quote.unique.to_i
  end

  def test_quotes_should_store_unique_in_different_field
    u=users(:basic_user)
    quote = u.invoices.create and quote.save_quote!
    quote.unique = 789123
    assert_equal 789123, quote.quote_unique_number.to_i
    assert_equal 789123, quote.unique.to_i
  end


  def test_quote_numbering_should_mimic_invoices_numbering
    u=users(:basic_user)
    delete_invoices

    quote_a = u.invoices.create and quote_a.save_quote!
    quote_a.update_attributes :unique => 1000

    quote_b = u.invoices.create and quote_b.save_quote!
    quote_b.update_attributes :unique => 25
    quote_c = u.invoices.create and quote_c.save_quote!
    assert_equal "26", quote_c.unique
  end

  def test_quote_should_regenerate_number_after_conversion_to_invoice
    delete_invoices
    u=users(:basic_user)

    quote_a = u.invoices.create and quote_a.save_quote!
    quote_a.update_attributes :unique => 1000

    quote_a.convert_quote_to_invoice!

    assert_equal 1000, quote_a.quote_unique_number.to_i, "should keep old quote number in a separate field"
    assert_equal 1, quote_a.unique.to_i, "should get a new unique number as an invoice"

    quote_b = u.invoices.create and quote_b.save_quote!
    assert_equal 1001, quote_b.unique.to_i, "new quote should know about number of quote previously converted"
  end

  def test_should_validate_uniqueness_of_quote_number
    delete_invoices
    u=users(:basic_user)
    quote_a = u.invoices.create and quote_a.save_quote!
    quote_b = u.invoices.create and quote_b.save_quote!
    assert ! quote_b.update_attributes(:quote_unique_number => quote_a.quote_unique_number)
    assert ! quote_b.errors[:quote_unique_number].blank?
  end

  def test_should_validate_uniqueness_of_invoice_number
    delete_invoices
    u=users(:basic_user)
    invoice_a = u.invoices.create
    invoice_b = u.invoices.create :unique_number => invoice_a.unique_number
    assert ! invoice_b.errors[:unique_number].blank?
  end

  def test_quotes_should_not_support_payments
    q = invoices(:quote_sent)
    assert !q.payment_recordable?
    assert_raise StandardError do
      q.assert_payable_by(Payment.new)
    end
  end

  # Recurring invoices

  def test_should_create_recurring_from_regular

    prototype = invoices(:invoice_no_tax_settings_with_customer_disabled_tax_settings)
    recurring = Invoice.create_recurring_from(prototype, {:frequency=>"monthly"})

    assert_equal 2, recurring.created_by.id
    assert_equal 53, recurring.customer_id
    assert_equal 1, recurring.line_items.count
    assert_equal prototype.line_items[0].attributes.except("id","invoice_id","updated_at"), recurring.line_items[0].attributes.except("id","invoice_id", "updated_at")
    assert_not_equal prototype.line_items[0].id, recurring.line_items[0].id, "should be a deep copy (separate line items objects)"

    assert_equal 'recurring', recurring.status
    assert_equal 'Recurring Invoice', recurring.meta_status_string

    assert_equal "", recurring.unique
    assert_equal "monthly", recurring.schedule.frequency

    assert_equal recurring.id, prototype.reload.recurring_invoice_id, "prototype should be associated with recurring invoice"
    assert recurring.valid?
  end

  def test_should_not_create_sendable_recurring_from_incomplete
    prototype = invoices(:draft_invoice)
    prototype.line_items.delete_all

    recurring = Invoice.create_recurring_from prototype, {:frequency=>:monthly, :send_recipients=>"bill-door@example.com"}

    assert ! recurring.errors.empty?
  end

  def test_should_generate_new_issue_date_for_recurring_invoice

    Time.stubs(:now).returns(Time.parse("2009-1-1 00:00:00+00:00").utc)

    sequences = [
      {:frequency => "monthly",  :dates =>%w[2009-2-28 2009-3-31 2009-4-30]},
      {:frequency => :monthly, :dates =>%w[2009-4-1 2009-5-1 2009-6-1]},
      {:frequency => :monthly,  :dates =>%w[2009-4-15 2009-5-15 2009-6-15]},
      {:frequency => :monthly,  :dates =>%w[2009-1-28 2009-2-28 2009-3-31]},
      #TODO: above should work like this {:frequency => :monthly, :dates =>%w[2009-1-28 2009-2-28 2009-3-28]}
      {:frequency => :monthly,  :dates =>%w[2009-1-29 2009-2-28 2009-3-31]},
      #TODO: above should work like this: #{:dates =>%w[2009-1-29 2009-2-28 2009-3-29]}

      {:frequency => :weekly, :dates =>%w[2009-1-1 2009-1-8 2009-1-15]} ,
      {:frequency => :weekly, :dates =>%w[2009-12-30 2010-1-6 2010-1-13]},

      {:frequency => :yearly, :dates =>%w[2009-1-14 2010-1-14 2011-1-14]},
      #{:frequency => :yearly, :dates => %w[2012-2-29 2013-2-28 2014-2-28 2015-2-28 2016-2-29] },  #TODO: should work like this
      {:frequency => :yearly,  :dates => %w[2012-2-29 2013-2-28 2014-2-28 2015-2-28 2016-2-28] },
      {:frequency => :yearly, :dates => %w[2011-3-1 2012-3-1 2013-3-1] }

      ]

    sequences.each do |seq|

      seq[:dates].map!{|e|  DateTime.parse(e).to_date }

      @invoice = invoices(:invoice_no_tax_settings_with_customer_disabled_tax_settings)
      @invoice.date = seq[:dates].shift
      @recurring = Invoice.create_recurring_from @invoice, :frequency=>seq[:frequency]
      assert_equal  seq[:dates].shift, @recurring.date

      seq[:dates].each do |expected_date|
        @recurring.new_issue_due_dates!
        assert_equal expected_date, @recurring.date
      end

    end

  end

  def test_should_generate_new_due_date_for_recurring_invoice

    Time.stubs(:now).returns(Time.parse("2009-1-1 00:00:00+00:00").utc)

    sequences = [
      {:input => ["2009-2-28","2009-3-5"],:output => ["2009-3-31","2009-4-5"]},
      {:input => ["2009-4-29","2009-5-6"], :output => ["2009-5-29","2009-6-5"]},
      {:input => ["2009-4-15",nil], :output => ["2009-6-15",nil]},
      ]

    sequences.each do |seq|
      seq.each_key {|key| seq[key] =  seq[key].map{|e|  e.nil? ? nil : DateTime.parse(e).to_date } }

      @invoice = invoices(:invoice_no_tax_settings_with_customer_disabled_tax_settings)
      @invoice.date = seq[:input][0]
      @invoice.due_date = seq[:input][1]

      @recurring = Invoice.create_recurring_from(@invoice, {:frequency=>"monthly"})
      assert_equal seq[:output][1], @recurring.due_date
    end
  end

  def test_should_query_recurring_invoices
    @invoices = Invoice.recurring
    assert_equal @invoices.size, 3
    assert_equal @invoices.map(&:id), [91,92,93]

    #TODO: support calls like below
    #assert_equal 91, Invoice.recurring.find(:first).id
  end

#  def test_should_calculate_recurring_due_time
#    @invoice = invoices(:recurring)
#    @invoice.date = Date.civil(2010,07,24)
#    @invoice.created_by.settings[:time_zone] = "GMT"
#    @invoice.new_issue_due_dates!
#    assert_equal Time.parse("2010-07-24 03:00:00+00:00").utc, @invoice.due_date
#
#    @invoice.date = Date.civil(2010,07,24)
#    @invoice.created_by.settings[:time_zone] = "US/Pacific"
#    @invoice.new_issue_due_dates!
#    assert_equal Time.parse("2010-07-24 10:00:00+00:00").utc, @invoice.due_date
#  end

  def test_should_process_recurring

    recurring = invoices(:recurring)

    assert_difference 'Invoice.count', +1 do
      recurring.process_recurring!
    end

    invoice = Invoice.find :first, :order=>"id DESC"

    # regular data should be copied
    assert_equal 1, invoice.created_by.id
    assert_equal 1, invoice.customer_id
    assert_equal 1, invoice.line_items.count
    assert_equal recurring.line_items[0].attributes.except("id","invoice_id","updated_at"), invoice.line_items[0].attributes.except("id","invoice_id", "updated_at")
    assert_not_equal recurring.line_items[0].id, invoice.line_items[0].id, "should be a deep copy (separate line items objects)"

    assert_equal 'draft', invoice.status

    assert_equal Date.civil(2009,9,24), invoice.date

    assert invoice.unique_number.to_i > 0

    assert invoice.valid?

    recurring.reload
    assert_equal Date.civil(2009,10,24), recurring.date
    assert_equal Date.civil(2009,10,27), recurring.due_date

    #assert_equal BigDecimal.new("20"), invoice.tax_1_amount
  end

  def test_should_not_create_recurring_invoices_with_issue_dates_in_past
    invoice = invoices(:sent_invoice)
    invoice.date = Date.new(1999,01,20)

    Time.stubs(:now).returns(Time.parse("2009-07-24 03:00:00+00:00").utc)
    recurring = Invoice.create_recurring_from(invoice, {:frequency=>"monthly"})
    assert_equal Date.new(2009,8,20), recurring.date


    Time.stubs(:now).returns(Time.parse("2009-08-20 22:00:00+00:00").utc)
    invoice.created_by.settings[:time_zone] = "Asia/Ulaanbaatar"
    recurring = Invoice.create_recurring_from(invoice, {:frequency=>"monthly"})
    assert_equal Date.new(2009,9,20), recurring.date

  end

  def test_should_not_create_sendable_recurring_with_zero_total_amount
    prototype = invoices(:sent_invoice)

    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"email@example.com")
    assert prototype.valid?
    assert recurring.recurring?

    prototype = invoices(:sent_invoice)
    prototype.recurring_invoice = nil #so that we can use this prototype again
    prototype.update_attributes :line_items => []
    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"email@example.com")
    
    assert ! recurring.errors.empty?
    assert recurring.errors[:send_recipients].include? "total amount"
  end

  def test_should_not_create_sendable_recurring_wihout_customer
    prototype = invoices(:sent_invoice)

    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"email@example.com")
    assert prototype.valid?
    assert recurring.recurring?

    prototype.recurring_invoice = nil
    prototype.customer = nil
    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"email@example.com")    
    assert ! recurring.valid?
    assert recurring.errors[:send_recipients].include? "customer"
  end

  def test_should_validate_send_recipients
    prototype = invoices(:sent_invoice)

    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"anumbrella")
    assert ! recurring.valid?

    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"anumbrella@example.com")
    assert recurring.valid?

    recurring = Invoice.create_recurring_from(prototype, :frequency=>"monthly", :send_recipients=>"")
    assert recurring.valid?
  end

  def test_should_log_send_when_recurring_invoice_is_sent
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    recurring = invoices(:recurring_sendable)
    assert_difference('Activity.count') do
      recurring.process_recurring!
    end
  end

  def test_recurring_invoice_should_associate_generated_invoices
    recurring = invoices(:recurring_sendable)
    recurring.generated_invoices.delete_all

    recurring.process_recurring!
    recurring.process_recurring!
    recurring.process_recurring!

    assert_not_nil recurring.generated_invoices
    assert_equal 3, recurring.generated_invoices.count
  end


end
