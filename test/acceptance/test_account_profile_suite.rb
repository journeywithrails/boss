#include tests that deals with user accounts

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) +'/814_cas_test'
require File.dirname(__FILE__) +'/33_tax_preferences_test'
require File.dirname(__FILE__) +'/38_company_information_test'

# Add in tests which were missing from the suites.  Organize them later.
require File.dirname(__FILE__) + '/270_remail_activation_test'
require File.dirname(__FILE__) + '/10_apply_taxes_on_invoice_a_test'
require File.dirname(__FILE__) + '/38_company_information_test'
require File.dirname(__FILE__) + '/29_customer_summary_list_test'
require File.dirname(__FILE__) + '/74_preview_invoice_in_HTML_test'
require File.dirname(__FILE__) + '/68_paypal_express_round_trip_via_sandbox'
require File.dirname(__FILE__) + '/87_accept_invitation_test'
require File.dirname(__FILE__) + '/270_reset_password_test'
require File.dirname(__FILE__) + '/15_terms_on_invoice_details_test'
require File.dirname(__FILE__) + '/126_invoice_numbering_test'
require File.dirname(__FILE__) + '/21_email_invoice_as_html_link_test'
require File.dirname(__FILE__) + '/10_apply_taxes_on_invoice_b_test'
require File.dirname(__FILE__) + '/87_send_bookkeeping_invitation'
require File.dirname(__FILE__) + '/271_referral_test'
require File.dirname(__FILE__) + '/272_contest_test'
require File.dirname(__FILE__) + '/273_protect_forms_test'
require File.dirname(__FILE__) + '/beanstream_test_suite'
require File.dirname(__FILE__) + '/homepage_acceptance_test'
require File.dirname(__FILE__) + '/rac_contest_test'
require File.dirname(__FILE__) + '/reports_test'
 class TS_accounts_profile 
   def self.suite
     suite = Test::Unit::TestSuite.new("TS_accounts_profile")
     suite << LoginTest.suite
     suite << SignupTest.suite
     suite << TaxPreferencesTest.suite
     suite << CompanyInformationTest.suite
     suite << InvoiceProfile.suite     
     
         
    # Add in tests which were missing from the suites.  Organize them later.
    suite << RemailActivationTest.suite # 270_remail_activation_test.rb
    suite << ApplyTaxesATest.suite # 10_apply_taxes_on_invoice_a_test.rb
    suite << CustomerSummaryListTest.suite # 29_customer_summary_list_test.rb
    suite << PreviewInvoiceInHtml.suite # 74_preview_invoice_in_HTML_test.rb
    suite << AcceptBookkeepingInvitation.suite # 87_accept_invitation_test.rb
    suite << ResetPasswordTest.suite # 270_reset_password_test.rb
    suite << TermsOnInvoiceDetailsTest.suite # 15_terms_on_invoice_details_test.rb
    suite << InvoiceNumberingTest.suite # 126_invoice_numbering_test.rb
    suite << EmailInvoiceAsHTMLLink.suite # 21_email_invoice_as_html_link_test.rb
    suite << ApplyTaxesBTest.suite # 10_apply_taxes_on_invoice_b_test.rb
    suite << SendBookkeepingInvitation.suite # 87_send_bookkeeping_invitation.rb
    #suite << PaypalExpressRoundTrip.suite # 68_paypal_express_round_trip_via_sandbox.rbrequire File.dirname(__FILE__) + '/271_referral_test'
    suite << ContestTest.suite
    suite << ProtectFormstest.suite
    suite << BeanstreamTestSuite.suite
    suite << HomepageAcceptanceTest.suite
    suite << RacContestTest.suite
    suite << ReportsTest.suite
     return suite
   end   
 end
 

b = SageTestSession.create_browser()
$external_browser_instance = b
Test::Unit::UI::Console::TestRunner.run(TS_accounts_profile)
b.close
