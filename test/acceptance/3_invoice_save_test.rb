$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# remove all tests here because they are tested elsewhere already
# User can save Invoice
class InvoiceSaveTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices
  
  def setup
    @user = watir_session.with(:user_without_profile)
    @user.logs_in
  end
  
  def teardown
    @user.teardown
  end
  


end