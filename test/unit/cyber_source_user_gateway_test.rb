require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../billing_helper'

class CyberSourceUserGatewayTest < Test::Unit::TestCase
  def test_validate
    ug = CyberSourceUserGateway.new(:gateway_name => 'cyber_source',
                                   :user_id => 1,
                                   :login => 'b',
                                   :password => 'a')
    ug.valid?
    assert_equal [], ug.errors.full_messages
  end

end
