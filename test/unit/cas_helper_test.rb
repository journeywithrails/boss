require File.dirname(__FILE__) + '/../test_helper'

class CasHelperTest < Test::Unit::TestCase
  def setup
  end
  
  def teardown
  end

  class MockController
    def session
      @session ||= {}
    end
    
    def reset_session
      @session = {}
    end
  end
  
  def test_should_stub_cas_logged_in_and_out_in_same_test
    controller = MockController.new
    user = mock_user
    stub_cas_logged_in(user)
    result = false
    assert_nothing_raised(Exception) do
      result = CASClient::Frameworks::Rails::Filter.filter(controller)
    end
    assert result
    assert_equal fake_user_id, controller.session[:user]
    assert_equal fake_user_name, controller.session[:sage_user]


    controller.expects(:redirect_to).with('/access/denied')
    stub_cas_logged_out
    assert_nothing_raised(Exception) do
      result = CASClient::Frameworks::Rails::Filter.filter(controller)
    end
    deny result
    assert_nil controller.session[:user]
    assert_nil controller.session[:sage_user]
  end

  private
  
  def mock_user
    user = mock('user')
    user.stubs(:id).returns(fake_user_id)
    user.stubs(:sage_username).returns(fake_user_name)
    user.stubs(:email).returns(fake_user_name+"@billingboss.com")
    user
  end
  
  def fake_user_id
    7
  end
  
  def fake_user_name
    'bob'
  end
end