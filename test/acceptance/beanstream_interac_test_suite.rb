
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/helpers/payment_acceptance_helper'

class BeanstreamInteracTestSuite < SageAccepTestCase
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

  def test_interac_payment
    invoice, payment_url = 
      begin_payment_with_interac
    use_interac_online_emulator :succeed => true
    assert_successfully_paid(invoice)
    view_paid_invoice(payment_url)
    assert_payment_state :beanstream_interac, :cleared
  end

  def test_interac_payment_declined
    invoice, payment_url = 
      begin_payment_with_interac
    use_interac_online_emulator :succeed => false
    assert_payment_state :beanstream_interac, :created
    view_unpaid_invoice(payment_url)
  end
end
