$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/tax_test_helper'

# Test cases for User Story 10
# Apply taxes on invoice

# Description: As a user, I want to apply taxes on my invoice so that
# I can charge taxes on my customers and remit taxes to the government.

class ApplyTaxesATest < SageAccepTestCase
  include AcceptanceTestSession
  include Sage::TaxTestHelper
  fixtures :users, :customers, :invoices, :line_items

  def setup
    @user = watir_session.with(:complete_user)
    @user.logs_in 
    @debug = false
  end
  
  def teardown
    @debug = false
    @user.teardown
  end
  
  # User acceptance tests 
    # 1. Tax rate is per invoice.
    # 2. Users can select which tax to apply on an invoice.
    # 3. Once the tax has been changed, the grand total of the invoice is updated automatically and tax is recalculated
    # 4. The total tax charged is listed on the invoice
    # 5. Once price, quantity, discount are changed, tax is recalculated.
    
  def test_switch_taxes_off_in_profile_and_check_new_invoice_has_taxes_disabled
    $test_ui.agree('continue?', true) if @debug
    update_profile_taxes(
              :tax_enabled => false)

    
    deny @profile.tax_enabled, "after setting tax_enabled to false on profile page, profile.tax_enabled was not false"
    goto_new_invoice_url     

    $test_ui.agree('continue?', true) if @debug

    deny_tax_enabled_name_and_rate_exist(
      "after disabling taxes in profile settings and creating a new invoice",
              :tax_1_enabled => @profile.tax_1_enabled,
              :tax_1_name => @profile.tax_1_name,
              :tax_1_rate => @profile.tax_1_rate,                  
              :tax_2_enabled => @profile.tax_1_enabled,
              :tax_2_name => @profile.tax_2_name,
              :tax_2_rate => @profile.tax_2_rate)
    @debug = false
  end
    
  def test_switch_taxes_on_in_profile_and_check_new_invoice_has_taxes_enabled
    update_profile_taxes(
              :tax_enabled => true)
    
    goto_new_invoice_url        
    affirm_tax_enabled_name_and_rate_exist(
              "after enabling taxes in profile settings and creating a new invoice",
              :tax_1_enabled => @profile.tax_1_enabled,
              :tax_1_name => @profile.tax_1_name,
              :tax_1_rate => @profile.tax_1_rate,                  
              :tax_2_enabled => @profile.tax_1_enabled,
              :tax_2_name => @profile.tax_2_name,
              :tax_2_rate => @profile.tax_2_rate)
  end
  
  def test_change_name_and_rate_in_profile_and_check_new_invoice_has_name_and_rate
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_name => "tax 1 name changed",
              :tax_1_rate => 10.0)
    
    goto_new_invoice_url
    verify_invoice_view_fields(
              :tax_1_name => "tax 1 name changed",
              :tax_1_rate => 10.0)
  end
    
  def test_change_name_and_rate_in_profile_and_check_existing_invoice_does_not_have_changed_name_and_rate
    add_standard_invoice_and_click_submit
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_name => "tax 1 name changed",
              :tax_1_rate => 10.0)
    
    exit unless $test_ui.agree('did update_profile_taxes. continue?', true) if @debug || $debug
    @user.edits_invoice(@standard_invoice.id)
    # invoice_tax_1_enabled
    exit unless $test_ui.agree('did edits_invoice. continue?', true) if @debug || $debug
    verify_invoice_view_fields(
              :tax_1_enabled => @standard_invoice.tax_1_enabled,    
              :tax_1_name => @standard_invoice.tax_1_name,
              :tax_1_rate => @standard_invoice.tax_1_rate,
              :tax_2_enabled => @standard_invoice.tax_2_enabled,                            
              :tax_2_name => @standard_invoice.tax_2_name,
              :tax_2_rate => @standard_invoice.tax_2_rate)
    $debug = false
  end
  
  def test_switch_taxes_off_in_profile_and_check_existing_invoice_has_taxes
    
    add_standard_invoice_and_click_submit
    
    update_profile_taxes(
              :tax_enabled => false)
    
    @user.edits_invoice(@standard_invoice.id)
    verify_invoice_view_fields(
              :tax_1_enabled => @standard_invoice.tax_1_enabled,
              :tax_1_name => @standard_invoice.tax_1_name,
              :tax_1_rate => @standard_invoice.tax_1_rate,
              :tax_2_enabled => @standard_invoice.tax_2_enabled,              
              :tax_2_name => @standard_invoice.tax_2_name,
              :tax_2_rate => @standard_invoice.tax_2_rate)
  end
  
  def test_select_calculated_discount_before_tax_in_profile_and_check_new_invoice_calculate_taxes_before_discount
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => true)
    
    add_standard_invoice_and_click_submit
    
    verify_invoice_tax_data_fields(
              @standard_invoice,
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.31,
              :total_amount => 17.25)
  end
  
  def test_deselect_calculated_discount_before_tax_in_profile_and_check_new_invoice_calculate_taxes_after_discount
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => false)
    
    add_standard_invoice_and_click_submit
    verify_invoice_tax_data_fields(
              @standard_invoice,
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.35,
              :total_amount => 17.21)
  end
  
  def test_change_calculate_discount_before_tax_in_profile_and_check_existing_invoice_is_not_changed
    exit unless $test_ui.agree('start?', true) if @debug
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => true)
    
    exit unless $test_ui.agree('did update_profile_taxes. continue?', true) if $debug
    
    add_standard_invoice_and_click_submit

    exit unless $test_ui.agree('did add_standard_invoice_and_click_submit. continue?', true) if @debug
    update_profile_taxes(
              :discount_before_tax => false)
              
    verify_invoice_tax_data_fields(
              @standard_invoice,
              :line_items_total => 15.54,
              :tax_1_amount => 1.09,
              :tax_2_amount => 0.93,
              :discount_amount => 0.31,
              :total_amount => 17.25)
              
  end
  
  # no test for remove row, separate defect test  
  def test_check_tax_calculation_on_new_invoice_with_discount_before_tax
    @debug = false
    update_profile_taxes(
              :tax_enabled => true,
              :tax_1_rate => 7.0,
              :tax_2_rate => 6.0,
              :discount_before_tax => true)

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
          
       
    add_standard_invoice_update_tax_and_verify(
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
              
    add_standard_invoice_update_tax_and_verify(
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
              
    add_standard_invoice_update_tax_and_verify(
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
              
    add_standard_invoice_update_tax_and_verify(
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
              
    add_standard_invoice_update_tax_and_verify(
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
              
    add_standard_invoice_update_tax_and_verify(
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

    #change_discount_percent_and_rates(5.55, 10.0, 11.11)    
    expected_after = {    
              :line_items_total => 15.54,
              :tax_1_amount => 1.55,
              :tax_2_amount => 1.73,
              :discount_amount => 0.86,
              :total => 17.96}
              
    add_standard_invoice_update_tax_and_verify(
              expected_before, 
              expected_after
    ) {change_discount_percent_and_rates(5.55, 10.0, 11.11)}


    b = @user.b

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
    add_standard_invoice
    
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
    
    @user.wait    
    
    verify_invoice_view_fields(
              :line_items_total => 18.87,
              :tax_1_amount => 1.32,
              :tax_2_amount => 1.13,
              :discount_amount => 0.38,
              :total => 20.94)    
  end
  
    
end
