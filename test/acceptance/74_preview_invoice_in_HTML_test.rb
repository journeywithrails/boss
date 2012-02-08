$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

#remove duplicate test
# Test cases for User Story 74
# Users can preview the Invoice in HTML
# before sending
class PreviewInvoiceInHtml < SageAccepTestCase

  include AcceptanceTestSession
  fixtures :users, :invoices, :customers
  
  def setup
    @user = watir_session.with(:user_without_profile)
    @user.logs_in
    @number_of_line_items = 5
  end
  
  def teardown
   @user.teardown
  end
end
