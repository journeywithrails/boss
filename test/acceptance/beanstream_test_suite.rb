
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/helpers/payment_acceptance_helper'

class CybersourceTestSuite < SageAccepTestCase
  include AcceptanceTestSession
  include PaymentAcceptanceHelper
  fixtures :users
  fixtures :invoices

  def setup
    @u = users(:basic_user)
    @user = watir_session.with(:basic_user)
    @user.logs_in
    start_email_server
  end

  def teardown
    end_email_server
    @u = nil
    @user.teardown
  end

  def test_cyber_source_payment
    test_typical_gateway(:gateway => :cyber_source,
                         :payment_methods => [:visa, :master],
                         :currency => 'USD',
                         :skip_address_fields => [:name, :phone, :fax],
                         :decline_message => 'One or more fields contains invalid data'
                        )
  end

end
