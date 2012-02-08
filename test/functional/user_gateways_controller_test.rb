require File.dirname(__FILE__) + '/../test_helper'

class UserGatewaysControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    login_as :basic_user
  end
  
  def test_accept_simply_gateway
    token = ApiToken.new
    @controller.expects(:api_token?).at_least_once.returns(true)
    @controller.expects(:api_token).at_least_once.returns(token)
    user_gateway = UserGateway.new
    user_gateway.stubs(:id).returns(42)
    token.user_gateway = user_gateway
    token.user_gateway_id = 42
    get :switch_to_sps
    assert_response :success
    assert_template('user_gateways/simply/switch_to_sps')
  end

  def test_update_gateway_in_browsal
    token = ApiToken.new
    @controller.expects(:api_token?).at_least_once.returns(true)
    @controller.expects(:api_token).at_least_once.returns(token)
    user_gateway = UserGateway.new
    user_gateway.stubs(:id).returns(42)
    token.user_gateway = user_gateway
    token.user_gateway_id = 42
    user_gateway.expects(:set_active)
    put :update, :id => '42'
    assert_redirected_to "/deliveries/new"
  end
  
  def test_update_gateway_not_in_browsal
    @controller.expects(:api_token?).at_least_once.returns(false)
    params = {'mock' => "stub"}
    UserGateway.expects(:set).with(users(:basic_user), params)
    put :update, :user_gateways => params
    assert_redirected_to profiles_url
  end
  
  protected
  def a_gateway(user)
    gateway = SageSbsUserGateway.new
    gateway.gateway_name = 'sage_sbs'
    gateway.merchant_id = '123' #required to pass validity checks
    gateway.currency = 'CAD'
    gateway.merchant_key = 'abc'
    gateway.user = user
    gateway.active = false
    gateway.save!
    gateway
  end

end
