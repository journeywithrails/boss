$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/tax_test_helper'
# Test cases for User Story 10
# Apply taxes on invoice

# Description: As a user, I want to apply taxes on my invoice so that
# I can charge taxes on my customers and remit taxes to the government.

class ApplyTaxesBTest < SageAccepTestCase
  include AcceptanceTestSession
  include Sage::TaxTestHelper
  fixtures :users, :customers, :invoices, :line_items

  def setup
    @user = watir_session.with(:complete_user)
    @user.logs_in 
    @debug = false
  end
  
  def teardown
    @user.teardown
  end
  
  # User acceptance tests 
    # 1. Tax rate is per invoice.
    # 2. Users can select which tax to apply on an invoice.
    # 3. Once the tax has been changed, the grand total of the invoice is updated automatically and tax is recalculated
    # 4. The total tax charged is listed on the invoice
    # 5. Once price, quantity, discount are changed, tax is recalculated.

  def test_check_tax_calculation_on_edited_invoice_with_discount_before_tax
    @debug = false
    expected_before = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.31,
              :total => 17.25}              
              
    # uncheck_both_taxes                  
    expected_after = {
              :line_items_total => 15.54,
              :tax_1_amount => 0.00,
              :tax_2_amount => 0.00,
              :discount_amount => 0.31,
              :total => 15.23}   
          
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {uncheck_both_taxes}
    
    # uncheck_tax_1
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 0.00,
              :tax_2_amount => 0.93,
              :discount_amount => 0.31,
              :total => 16.16}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {uncheck_tax_1}
    
    # uncheck_tax_2
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.00,
              :discount_amount => 0.31,
              :total => 16.32}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {uncheck_tax_2}
    
    # change tax rate 1
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 0.93,
              :discount_amount => 0.31,
              :total => 17.71}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_tax_1_rate(10.00)}

    #change_tax_2_rate
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 1.73,
              :discount_amount => 0.31,
              :total => 18.05}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_tax_2_rate(11.11)}

    #change_discount_amount
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 5.55,
              :total => 12.01}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_amount(5.55)}

    #change_discount_percent
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.86,
              :total => 16.70}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_percent(5.55)}

    #change_discount_amount_and_rates(5.55, 10.0, 11.11)
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 1.73,
              :discount_amount => 5.55,
              :total => 13.27}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_amount_and_rates(5.55, 10.0, 11.11)}

    #change_discount_percent_and_rates(5.55, 10.0, 11.11)    
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 1.73,
              :discount_amount => 0.86,
              :total => 17.96}
              
    edit_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_percent_and_rates(5.55, 10.0, 11.11)}


    b = @user.b

    #change_qty
    @user.edits_invoice(invoices(:discount_before_tax_invoice).id)
    
    verify_invoice_view_fields(
              :line_items_total => expected_before[:line_items_total],
              :tax_1_amount => expected_before[:tax_1_amount],
              :tax_2_amount => expected_before[:tax_2_amount],
              :discount_amount => expected_before[:discount_amount],
              :total => expected_before[:total])    
              
    #get newly added last row in the table and change quantity
    trows = @user.line_items_rows
    assert_equal 3, trows.length
    tr = trows[::WatirBrowser.item_index(trows.length)]
    assert tr.exists?
    @user.expects_ajax(1) do
      @user.populate(tr.text_field(:name, "invoice[line_items_attributes][][quantity]"), '4')
      #tr.text_field(:name, "invoice[line_items_attributes][][quantity]").set('4')
    end
    
    @user.wait    
    
    verify_invoice_view_fields(
              :line_items_total => 18.87,
              :tax_1_amount => 1.32,
              :tax_2_amount => 1.13,
              :discount_amount => 0.38,
              :total => 20.94)    
              
    #change_price
    @user.edits_invoice(invoices(:discount_before_tax_invoice).id)
    
    verify_invoice_view_fields(
              :line_items_total => expected_before[:line_items_total],
              :tax_1_amount => expected_before[:tax_1_amount],
              :tax_2_amount => expected_before[:tax_2_amount],
              :discount_amount => expected_before[:discount_amount],
              :total => expected_before[:total])    
              
    #get newly added last row in the table and change price
    trows = @user.line_items_rows
    assert_equal 3, trows.length
    tr = trows[::WatirBrowser.item_index(trows.length)]
    assert tr.exists?
    @user.expects_ajax(1) do
      @user.populate(tr.text_field(:name, "invoice[line_items_attributes][][price]"), '4.44')
      #tr.text_field(:name, "invoice[line_items_attributes][][price]").set('4.44')
    end
    
    verify_invoice_view_fields(
              :line_items_total => 18.87,
              :tax_1_amount => 1.32,
              :tax_2_amount => 1.13,
              :discount_amount => 0.38,
              :total => 20.94)    
    
  end

  def test_blank_tax_name_in_profile_and_check_that_tax_name_does_not_display_in_invoice
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_name => "")
    
    goto_new_invoice_url     
    # tax_1_name is empty, cannot check that it is not displayed
    deny_tax_enabled_name_and_rate_exist(
              "after enabling taxes but setting tax_1_name to blank and then creating a new invoice",
              :tax_1_enabled => @profile.tax_enabled,
              :tax_1_rate => @profile.tax_1_rate)
  end
  
  def test_blank_both_tax_names_do_not_display_in_invoice
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_name => "",
              :tax_2_name => "")
    
    goto_new_invoice_url     
    deny_tax_enabled_name_and_rate_exist(
              "after enabling taxes but setting both tax_1_name and tax_2_name to blank and then creating a new invoice",
              :tax_1_enabled => @profile.tax_enabled,
              :tax_1_rate => @profile.tax_1_rate,                  
              :tax_2_enabled => @profile.tax_enabled,
              :tax_2_rate => @profile.tax_2_rate)
  end
  
  def test_create_invoice_and_check_preview_still_has_the_same_tax_amounts
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => true)
    
    add_standard_invoice_and_click_submit
    verify_invoice_preview_fields(
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.31,
              :total => 17.25
    )
    
  end
  
  def test_discount_before_tax_show_discount_line_before_tax_line
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_name => "tax 1 name",
              :discount_before_tax => true)
    
    goto_new_invoice_url      
    # grab the invoice_total_block div and find the index of the discount and tax labels
    invoice_total_block_text = @user.div(:id, 'invoice_total_block').text    
    discount_label = invoice_total_block_text.index('Discount')
    tax_1_label = invoice_total_block_text.index('tax 1 name')    
    
    assert_not_nil(discount_label)
    assert_not_nil(tax_1_label)
    
    if @debug
      p "invoice_total_block_text = #{invoice_total_block_text}"
      p "discount_label = #{discount_label}"
      p "tax_1_label = #{tax_1_label}"      
    end
    
    assert(discount_label < tax_1_label)
  end
  
  def test_discount_after_tax_show_discount_line_after_tax_line
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_name => "tax 1 name",              
              :discount_before_tax => false)
    
    goto_new_invoice_url    
    # grab the invoice_total_block div and find the index of the discount and tax labels    
    invoice_total_block_text = @user.div(:id, 'invoice_total_block').text    
    discount_label = invoice_total_block_text.index('Discount')
    tax_1_label = invoice_total_block_text.index('tax 1 name')    
    
    assert_not_nil(discount_label)
    assert_not_nil(tax_1_label)
    
    if @debug
      p "invoice_total_block_text = #{invoice_total_block_text}"
      p "discount_label = #{discount_label}"
      p "tax_1_label = #{tax_1_label}"      
    end    
    
    assert(discount_label > tax_1_label)
  end
  
  ######## Trac #92: Update invoice total when line item is deleted
  def test_should_update_new_invoice_total_when_line_item_is_deleted
    update_profile_taxes(
      :tax_enabled => true,
      :tax_1_name => "tax 1 name",
      :tax_1_rate => "5.0",
      :tax_2_name => "",
      :discount_before_tax => false)
    
    @user.creates_new_invoice
    # the first line is created automatically, no need to click add line 
    @user.edits_line_item(1,:unit => 'line one', :quantity => '1', :price => '1.23')
    @user.adds_line_item(:unit => 'line two', :quantity => '1', :price => '4.56')
          
    verify_invoice_view_fields(
      :line_items_total => 5.79,
      :tax_1_amount => 0.29,
      :discount_amount => 0,
      :total => 6.08)
      
    @user.removes_line_item(1)

    verify_invoice_view_fields(
      :line_items_total => 4.56,
      :tax_1_amount => 0.23,
      :discount_amount => 0,
      :total => 4.79)
  end

  def test_should_update_existing_invoice_total_when_line_item_is_deleted
    update_profile_taxes(:tax_enabled => false, :discount_before_tax => true)
    add_standard_invoice_and_click_submit
    #discount 2%
    @user.edits_invoice(@standard_invoice.id)
    @user.removes_line_item(2)

    verify_invoice_view_fields(
      :line_items_total => 11.10,
      :discount_amount => 0.22,
      :total => 10.88)
  end

  def test_change_tax2_rate

 update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => false)

    expected_before = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.35,
              :total => 17.21}
            
        #change_tax_2_rate
    expected_after = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 1.73,
              :discount_amount => 0.37,
              :total => 17.99}

    add_standard_invoice_update_tax_and_verify(
              expected_before,
              expected_after
    ) {change_tax_2_rate(11.11)}

  end

  def test_change_qty

    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 6.0,
              :tax_2_rate => 7.0,
              :discount_before_tax => false)
            
    expected_before = {
              :line_items_total => 15.54,
              :tax_1_amount => 0.93,
              :tax_2_amount => 1.09,
              :discount_amount => 0.35,
              :total => 17.21}
      #change_qty
    add_standard_invoice

    verify_invoice_view_fields(
              :line_items_total => expected_before[:line_items_total],
              :tax_1_amount => expected_before[:tax_1_amount],
              :tax_2_amount => expected_before[:tax_2_amount],
              :discount_amount => expected_before[:discount_amount],
              :total => expected_before[:total])

    #get newly added last row in the table and change quantity
    trows = @user.line_items_rows
    assert_equal 3, trows.length
    tr = trows[::WatirBrowser.item_index(trows.length)]
    assert tr.exists?
    @user.expects_ajax(1) do
      @user.populate(tr.text_field(:name, "invoice[line_items_attributes][][quantity]"), '4')

    end
    
    verify_invoice_view_fields(
              :line_items_total => 18.87,
              :tax_1_amount => 1.13,
              :tax_2_amount => 1.32,
              :discount_amount => 0.43,
              :total => 20.89)
  end

  def test_check_tax_calculation_on_new_invoice_with_discount_after_tax
    
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => false)

    expected_before = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.35,
              :total => 17.21}              

    # uncheck_both_taxes                  
    expected_after = {
              :line_items_total => 15.54,
              :tax_1_amount => 0.00,
              :tax_2_amount => 0.00,
              :discount_amount => 0.31,
              :total => 15.23} 
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {uncheck_both_taxes}
    
    # uncheck_tax_1
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 0.00,
              :tax_2_amount => 0.93,
              :discount_amount => 0.33,
              :total => 16.14}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {uncheck_tax_1}
    
    # uncheck_tax_2
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.00,
              :discount_amount => 0.33,
              :total => 16.30}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {uncheck_tax_2}
    
    # change tax rate 1
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 0.93,
              :discount_amount => 0.36,
              :total => 17.66}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_tax_1_rate(10.0)}


    #change_discount_amount
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 5.55,
              :total => 12.01}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_amount(5.55)}

    #change_discount_percent
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.97,
              :total => 16.59}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_percent(5.55)}
    #change_discount_amount_and_rates(5.55, 10.0, 11.11)
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 1.73,
              :discount_amount => 5.55,
              :total => 13.27}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_amount_and_rates(5.55, 10.0, 11.11)}
    
  end


  def test_change_discount_percent_rates
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => false)

    expected_before = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.35,
              :total => 17.21}

    #change_discount_percent_and_rates(5.55, 10.0, 11.11)
    expected_after = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 1.73,
              :discount_amount => 1.04,
              :total => 17.78}

    add_standard_invoice_update_tax_and_verify(
              expected_before,
              expected_after
    ) {change_discount_percent_and_rates(5.55, 10.0, 11.11)}
  end

  def test_change_price_for_line_item
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => false)

    expected_before = {
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.35,
              :total => 17.21}

    #change_price
    add_standard_oneline_invoice

    verify_invoice_view_fields(
              :line_items_total => expected_before[:line_items_total],
              :tax_1_amount => expected_before[:tax_1_amount],
              :tax_2_amount => expected_before[:tax_2_amount],
              :discount_amount => expected_before[:discount_amount],
              :total => expected_before[:total])

    #get newly added last row in the table and change price
    trows = @user.line_items_rows
    assert_equal 1, trows.length
    tr = trows[::WatirBrowser.item_index(trows.length)]
    assert tr.exists?
    @user.expects_ajax(1) do
      @user.populate(tr.text_field(:name, "invoice[line_items_attributes][][price]"), '1.0')
    end

    verify_invoice_view_fields(
              :line_items_total => 14.00,
              :tax_1_amount => 0.98,
              :tax_2_amount => 0.84,
              :discount_amount => 0.32,
              :total => 15.50)
  end

  #### helper functions ####

    
end
