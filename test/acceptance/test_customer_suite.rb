#include tests that deals with user accounts

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) +'/25_customer_add_edit_test'
require File.dirname(__FILE__) +'/29_customer_summary_list_test'
require File.dirname(__FILE__) +'/200_customers_grid_test'
 class TS_customer
   def self.suite
     suite = Test::Unit::TestSuite.new("TS_customer")
     suite << CustomerAddEditTest.suite
     suite << CustomerSummaryListTest.suite     
     suite << CustomersOverviewTest.suite
     return suite
   end   
 end
 

b = SageTestSession.create_browser()
$external_browser_instance = b
Test::Unit::UI::Console::TestRunner.run(TS_customer)
b.close