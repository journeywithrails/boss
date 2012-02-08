
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/helpers/payment_acceptance_helper'

class BeanstreamTestSuite < SageAccepTestCase
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

  def test_beanstream_payment
    test_typical_gateway(:gateway => :beanstream,
                         :payment_methods => [:visa, :master],
                         :decline_message => 'DECLINE'
                        )
  end

  def test_cyber_source_payment
    test_typical_gateway(:gateway => :cyber_source,
                         :payment_methods => [:visa, :master],
                         :currency => 'USD',
                         :skip_address_fields => [:name, :phone, :fax],
                         :decline_message => 'One or more fields contains invalid data'
                        )
  end

  def test_beanstream_usd_payment
    test_typical_gateway(:gateway => :beanstream,
                         :payment_methods => [:visa, :master],
                         :currency => 'USD',
                         :decline_message => 'DECLINE'
                        )
  end

  def dont_test_profile_contents_and_js
    #@user.goto_profile_url

    #deny @user.b.text_field(:id, "user_gateway_merchant_key").exists?
    #deny @user.b.text_field(:id, "user_gateway_login").exists?
    #deny @user.b.text_field(:id, "user_gateway_password").exists?    
    #deny @user.b.text_field(:id, "user_gateway_merchant_id").exists?  
 
    #@user.b.radio(:id, "user_gateway_gateway_name_sage_sbs").click
    #@user.b.wait
    #sleep 3
    #assert @user.b.text_field(:id, "user_gateway_merchant_id").exists?
    #assert @user.b.text_field(:id, "user_gateway_merchant_key").exists?

    #@user.b.radio(:id, "user_gateway_gateway_name_beanstream").click
    #@user.b.wait
    #sleep 3

    #deny @user.b.text_field(:id, "user_gateway_merchant_key").exists?
    #assert @user.b.text_field(:id, "user_gateway_login").exists?
    #assert @user.b.text_field(:id, "user_gateway_password").exists?    
    #assert @user.b.text_field(:id, "user_gateway_merchant_id").exists?    
  end

end
