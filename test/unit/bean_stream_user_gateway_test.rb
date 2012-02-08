require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../billing_helper'

class BeanStreamUserGatewayTest < Test::Unit::TestCase
#  def test_validate_beanstream_not_setup_fails
#    u = users(:user_without_profile)
#    p = u.profile
#    p.enable_beanstream = '1'
#    assert !p.valid?, "beanstream must have associated information"
#  end

  def test_validate
    ug = BeanStreamUserGateway.new(:gateway_name => 'beanstream',
                                   :user_id => 1,
                                   :merchant_id => 'a',
                                   :login => 'b',
                                   :password => 'c',
                                   :currency => 'CAD')
    ug.valid?
    assert_equal [], ug.errors.full_messages
  end

 #def test_validate_beanstream_credentials_good
 #  #does nothing right now
 #end

 #def test_validate_beanstream_credentials_bad
 #  #does nothing right now
 #end

end
