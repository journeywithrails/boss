#include tests that deals with invoices

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require File.dirname(__FILE__) + '/../test_helper'

require File.dirname(__FILE__) +'/10_apply_taxes_on_invoice_a_test'
require File.dirname(__FILE__) +'/10_apply_taxes_on_invoice_b_test'
require File.dirname(__FILE__) +'/11_invoice_with_discount_test'
require File.dirname(__FILE__) +'/14_invoice_numbers_date_comment_test'
require File.dirname(__FILE__) +'/16_invoice_status_change_test'
require File.dirname(__FILE__) +'/2_invoice_can_create_new_test'
require File.dirname(__FILE__) +'/3_invoice_save_test'
require File.dirname(__FILE__) +'/4_invoice_lookup_modify_test'
require File.dirname(__FILE__) +'/5_invoice_remove_test'
require File.dirname(__FILE__) +'/7_invoice_with_customer_test'
require File.dirname(__FILE__) +'/8_line_items_crud_test'
require File.dirname(__FILE__) +'/9_invoice_quantity_price_test'
require File.dirname(__FILE__) +'/27_customer_and_contact_on_the_fly_test'
require File.dirname(__FILE__) +'/74_preview_invoice_in_HTML_test'
require File.dirname(__FILE__) +'/21_email_invoice_as_html_link_test'
require File.dirname(__FILE__) +'/59_invoices_overview_test'

 class TS_invoice_quick
   def self.suite
     suite = Test::Unit::TestSuite.new("TS_invoice_quick")
     suite << InvoiceWithDiscount.suite 
     suite << InvoiceCanNew.suite
     suite << InvoiceSaveTest.suite
     suite << InvoiceLookupModify.suite
     suite << InvoiceRemovalTest.suite
     suite << InvoiceWithCustomer.suite     
     suite << LineItemsCrud8Test.suite     
     suite << TermsOnInvoiceDetailsTest.suite
     suite << InvoicesOverviewTest.suite
     return suite
   end   
 end

 

b = SageTestSession.create_browser()
$external_browser_instance = b
# Test::Unit::UI::Console::TestRunner.run(TS_invoice_quick)
Test::Unit::UI::Console::TestRunner.run(TS_invoice_quick)
b.close
