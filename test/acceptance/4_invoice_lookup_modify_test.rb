$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

#removed all tests here because the invoice index page is only used in test mode. All functions are already tested in other tests
# Users can look up an existing invoice and modify it
class InvoiceLookupModify < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers
  
  def setup
    @user = watir_session.with(:user_without_profile)
    @user.logs_in
  end
  
  def teardown
    @user.teardown
  end
  
end