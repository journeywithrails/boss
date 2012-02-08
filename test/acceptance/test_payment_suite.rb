#include tests that deals with user accounts

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) +'/67_payments_record_offline_test'
require File.dirname(__FILE__) +'/67_record_payments_test'
require File.dirname(__FILE__) +'/sps_payment_test'
require File.dirname(__FILE__) +'/moneris_payment_test'
 class TS_payment_test_suite 
   def self.suite
     suite = Test::Unit::TestSuite.new("TS_payment_test_suite")
     suite << PaymentsRecordOfflineTest.suite
     suite << RecordPaymentsTest.suite     
     suite << SpsPaymentTest.suite
     suite << MonerisPaymentTest.suite
     return suite
   end   
 end
 
 

b = SageTestSession.create_browser()
$external_browser_instance = b
# Test::Unit::UI::Console::TestRunner.run(TS_payment_test_suite)
Test::Unit::UI::Console::TestRunner.run(TS_payment_test_suite)
b.close

