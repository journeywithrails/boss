#include tests that deals with user accounts

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require File.dirname(__FILE__) + '/../test_helper'

require File.dirname(__FILE__) +'/68_paypal_express_full_round_trip_via_sandbox'
require File.dirname(__FILE__) +'/68_paypal_express_round_trip_via_sandbox'

 class TS_paypal_test_suite 
   def self.suite
     suite = Test::Unit::TestSuite.new("TS_paypal_test_suite")
     if !$paypal_hidden
       suite << PaypalExpressFullRoundTrip.suite
       suite << PaypalExpressRoundTrip.suite     
     end
     return suite
   end   
 end
 



b = SageTestSession.create_browser()
$external_browser_instance = b
# Test::Unit::UI::Console::TestRunner.run(TS_paypal_test_suite)
Test::Unit::UI::Console::TestRunner.run(TS_paypal_test_suite)
b.close