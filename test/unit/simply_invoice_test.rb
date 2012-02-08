require File.dirname(__FILE__) + '/../test_helper'

class SimplyInvoiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:basic_user)
  end
  
  def teardown
    $log_on = false
  end
  
  def test_create_simply_invoice_dynamically
    i = Invoice.new(:invoice_type => "SimplyAccountingInvoice")
    assert i.class == SimplyAccountingInvoice
  end
  
  def test_always_use_unique_name
    i = Invoice.new(:invoice_type => "SimplyAccountingInvoice")
    i.unique = "1"
    assert i.send("unique_name") == "1"
    assert i.send("unique_number").blank?
  end
  
  def test_does_not_recalculate_totals
    i = Invoice.new(:invoice_type => "SimplyAccountingInvoice")
    i.subtotal_amount = 100.0
    i.calculate_discounted_total
    assert i.subtotal_amount == 100.0
  end
  
  def test_should_mark_paid
    i = @user.invoices.build(valid_simply_invoice_params(:total_amount => 100.0, :simply_amount_owing => 100.0))
    i.customer = @user.customers.first
    assert_equal BigDecimal('100.0'), i.amount_owing
    i.save(false)
    i.mark_paid!
    assert_equal BigDecimal('0'), i.amount_owing    
  end

  def test_sending_invoice_supercedes_other_invoices_with_same_guid
    ids = []
    # RADAR not sure why but I using create on the associations is not working properly -- the id of the invoice object doesn't get set
    # must be something to do with our overriding of Invoice.new to enforce type based on invoice_type param. Will figure out when becomes
    # a blocker. Copying this comment to invoice.rb too  -- mj

    delivery = OpenStruct.new(:mail_options => {'direct_payment_gateways' => []})
    
    3.times do
      i = @user.invoices.build(valid_simply_invoice_params)
      i.save!
      i.delivering(delivery)
      ids << i.id
    end
    
    delivery = OpenStruct.new(:mail_options => {'direct_payment_gateways' => []})
    
    i1 = Invoice.find(ids[0])
    i2 = Invoice.find(ids[1])
    i3 = Invoice.find(ids[2])
    assert_equal i3, i2.superceded_by
    assert_state i2, :superceded
    assert_equal i2, i1.superceded_by
    assert_state i1, :superceded
    assert_nil i3.superceded_by
    deny_state i3, :superceded
  end
  
  def test_creating_invoice_does_not_supercede_other_invoices_with_same_guid
    ids = []
    # RADAR not sure why but I using create on the associations is not working properly -- the id of the invoice object doesn't get set
    # must be something to do with our overriding of Invoice.new to enforce type based on invoice_type param. Will figure out when becomes
    # a blocker. Copying this comment to invoice.rb too  -- mj
    
    # Behavior change: If the Simply invoice is not sent, previous invoices are not superceded.

    3.times do
      i = @user.invoices.build(valid_simply_invoice_params)
      i.save!
      ids << i.id
    end
    i1 = Invoice.find(ids[0])
    i2 = Invoice.find(ids[1])
    i3 = Invoice.find(ids[2])
    assert_not_equal i3, i2.superceded_by
    assert_state i2, :draft
    assert_not_equal i2, i1.superceded_by
    assert_state i1, :draft
    assert_nil i3.superceded_by
    deny_state i3, :superceded
  end
  
  def test_setting_created_by_on_invoice_does_not_supercede_other_invoices_with_same_guid
    i = @user.invoices.build(valid_simply_invoice_params)
    i.save!
    
    super_i = SimplyAccountingInvoice.new(valid_simply_invoice_params)
    super_i.save(false)
    
    i.reload
    deny_state i, :superceded
    assert_nil i.superceded_by
    
    super_i.created_by = @user
    super_i.save!
    
    i.reload
    deny_state i, :superceded
    assert_nil i.superceded_by
  end
  
  def test_can_only_supercede_invoice_that_has_a_superceded_by_and_created_by
    i = @user.invoices.build(valid_simply_invoice_params)
    i.save!
    deny i.supercede!
    
    i.created_by = @user
    i.superceded_by = @user.invoices.find(:first)
    assert i.supercede!
  end
  
  def test_regular_invoice_not_supercedable
    i = Invoice.new
    deny i.supercedable?
  end
  
  def not_done_test_simply_invoice_supercedable
    i = SimplyAccountingInvoice.new
    assert i.supercedable?
  end
  
  def test_should_add_taxes_from_attributes
    i = @user.invoices.build(valid_simply_invoice_params(:simply_amount_owing => 100.0))
    tax_attrs = [
      {
        :name => "SimplyTax1",
        :rate => 10.0,
        :included => true,
        :amount => 9.0
      },
      {
        :name => "SimplyTax2",
        :rate => 5.0,
        :included => true,
        :amount => 4.5
      }
    ]
    i.build_taxes_with_attributes(tax_attrs, true)
    i.taxes.each do |t|
      t.save!
    end
    
    assert_equal BigDecimal('13.5'), i.tax_amount
  end
  
  def test_should_fix_tax_profile_keys_when_assigning_user
    tax_attrs = []
    tax_attrs << users(:complete_user).profile.tax_2.attributes.symbolize_keys.except(:id, :created_by, :parent_id, :taxable_id, :taxable_type, :enabled, :created_at, :updated_at)
    tax_attrs << users(:complete_user).profile.tax_1.attributes.symbolize_keys.except(:id, :created_by, :parent_id, :taxable_id, :taxable_type, :enabled, :created_at, :updated_at)
    
    i = Invoice.new(valid_simply_invoice_params(:simply_amount_owing => 100.0))
    i.save(false)
    i.build_taxes_with_attributes(tax_attrs, true)
    i.taxes.each do |t|
      t.save!
    end
    
    assert_equal users(:complete_user).profile.tax_2.name, i.tax_1.name
    assert_equal users(:complete_user).profile.tax_1.name, i.tax_2.name
    
    i.created_by = users(:complete_user)
    i.save(false)
    
    assert_equal users(:complete_user).profile.tax_1.name, i.tax_1.name
    assert_equal users(:complete_user).profile.tax_2.name, i.tax_2.name


    tax_attrs = []
    tax_attrs << users(:complete_user).profile.tax_1.attributes.symbolize_keys.except(:id, :created_by, :parent_id, :taxable_id, :taxable_type, :enabled, :created_at, :updated_at)
    tax_attrs << users(:complete_user).profile.tax_2.attributes.symbolize_keys.except(:id, :created_by, :parent_id, :taxable_id, :taxable_type, :enabled, :created_at, :updated_at)

    i = Invoice.new(valid_simply_invoice_params(:simply_amount_owing => 100.0))
    i.save(false)
    i.build_taxes_with_attributes(tax_attrs, true)
    i.taxes.each do |t|
      t.save!
    end
    
    assert_equal users(:complete_user).profile.tax_1.name, i.tax_1.name
    assert_equal users(:complete_user).profile.tax_2.name, i.tax_2.name
    
    i.created_by = users(:complete_user)
    i.save(false)
    
    assert_equal users(:complete_user).profile.tax_1.name, i.tax_1.name
    assert_equal users(:complete_user).profile.tax_2.name, i.tax_2.name
  end
  
  def test_should_fix_tax_profile_keys_when_assigning_user_when_some_taxes_are_nil
  end
  
  def test_should_return_json_for_overview
    json = invoices(:unsent_simply_accounting_invoice).to_json(Invoice.overview_listing_json_params)
    i = invoices(:unsent_simply_accounting_invoice)
    as_hash = ActiveSupport::JSON.decode(json)
    
    assert_equal 'draft', as_hash["status"]
    deny invoices(:unsent_simply_accounting_invoice).customer.name.blank?
    assert_equal invoices(:unsent_simply_accounting_invoice).customer.name, as_hash["customer_name"]
    assert_equal invoices(:unsent_simply_accounting_invoice).customer_id, as_hash["customer_id"]
    assert_equal 100.0, as_hash["total_amount"]
    assert_equal 85.0, as_hash["amount_owing"]
    assert_equal 'simply-accounting-invoice', as_hash["invoice_type_for_css"]
    assert_equal invoices(:unsent_simply_accounting_invoice).id, as_hash["id"]
  end
  
  private 
  def valid_simply_invoice_params(other_params={})
    {
      :invoice_type => "SimplyAccountingInvoice",
      :simply_guid => '12345678912345678912345678912345',
      :simply_amount_owing => '10',
      :total_amount => '10'
    }.merge(other_params)
  end
end
