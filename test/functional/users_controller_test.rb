require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase

  fixtures :users

  def setup
    @emails = ActionMailer::Base.deliveries
    @emails.clear    
    # Without this call stubbed out, it takes about 10 minutes to test this controller.
    UserMailer.stubs(:deliver_signup_notification)
    User.delete_all(:sage_username => 'quire')
  end

  def teardown
    unstub_cas
  end
  
  def test_thankyou
    user_id = login_as(:basic_user)
    @controller.stubs(:api_token?).returns true
    @controller.stubs(:api_token).returns(ApiToken.new(:mode => 'simply:signup'))
    get :thankyou, :id => user_id
    assert_template 'users/simply/thankyou'
    assert_layout "layouts/simply/main"
  end

  def test_thankyou_send_invoice_new_gateway
    $debug=true
    user_id = login_as(:basic_user)
    @controller.stubs(:api_token?).returns true
    gateway = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs')
    @controller.stubs(:api_token).returns(ApiToken.new(:mode => 'simply:send_invoice', :new_gateway => true, :user_gateway => gateway))
    get :thankyou, :id => user_id
    assert_template 'users/simply/thankyou'
    assert_tag :attributes => { :id => 'complete-btn' }
    assert_layout "layouts/simply/main"
  end
  
  def test_thankyou_send_invoice
    user_id = login_as(:basic_user)
    @controller.stubs(:api_token?).returns true
    gateway = UserGateway.new_polymorphic(:gateway_name => 'sage_sbs')
    @controller.stubs(:api_token).returns(ApiToken.new(:mode => 'simply:send_invoice', :new_gateway => false, :user_gateway => gateway))
    get :thankyou, :id => user_id
    assert_template 'users/simply/thankyou'
    assert_tag :attributes => { :id => 'send_invoice_now_content' }
    assert_layout "layouts/simply/main"
  end
  
  # TODO: sso test that ensures biller created when user autocreated from sageuser
  
  # def test_should_create_biller_with_user
  #   assert_difference 'Biller.count' do
  #     assert_difference 'User.count' do
  #       create_user
  #       assert_response :success
  #       assert @response.body.include?("Please wait...")
  #     end
  #   end
  # end


  
  def test_ssan_signup
    get :signup, {:signup_type => "ssan"}
    create_user
    u = User.find(:first, :conditions => {:sage_username => "quire"})
    assert_equal "ssan", u.signup_type
  end
  
  def test_soho_signup
    get :signup, {:signup_type => "soho"}
    create_user
    u = User.find(:first, :conditions => {:sage_username => "quire"})
    assert_equal "soho", u.signup_type    
  end
  
  def test_bad_session_still_soho
    get :signup, {:signup_type => "asdf"}
    create_user
    u = User.find(:first, :conditions => {:sage_username => "quire"})
    assert_equal "soho", u.signup_type    
  end
  
  def test_no_session_still_soho
    get :signup
    create_user
    u = User.find(:first, :conditions => {:sage_username => "quire"})
    assert_equal "soho", u.signup_type     
  end

  def test_credit_referral
    r = Referral.new
    r.referring_email = "me@me.com"
    r.referring_name = "me"
    r.friend_email = "you@you.com"
    r.referral_code = "asdf"
    r.sent_at = Time.now
    assert r.valid?
    r.save!
    id = r.id
    code = r.referral_code
    get :signup, :referral_code => code
    assert_equal r.referral_code, session[:referral_code]

    create_user
    assert_redirected_to first_profile_edit_url
    r = Referral.find(id)
    assert_not_nil r.accepted_at
    assert r.accepted_at > Time.now-1.minute # it is updating accepted date with just the date and no time
    deny r.user_id.blank?    
  end
  
  # TODO: move ucd tests to SAM
  
  # def test_see_ucd_checkbox_on_signup_page
  #   get :signup
  #   assert @response.body.include?("Sign me up")
  # end
  # 
  # def test_ucd_on_if_signed_up_with_checkbox_enabled
  #   post :create, :user_communications => "on", :user => { :login => 'quire@example.com', :email => 'quire@example.com',
  #     :password => 'quire', :password_confirmation => 'quire', :terms_of_service => '1' }
  #   u = User.find(:first, :conditions => {:sage_username => "quire"})
  #   assert !u.nil?
  #   assert_equal true, u.profile.mail_opt_in
  # end
  # 
  # 
  # def test_ucd_off_if_signed_up_with_checkbox_disabled
  #   post :create, :user_communications => "off", :user => { :login => 'quire@example.com', :email => 'quire@example.com',
  #     :password => 'quire', :password_confirmation => 'quire', :terms_of_service => '1' }
  #   u = User.find(:first, :conditions => {:sage_username => "quire"})
  #   assert !u.nil?
  #   assert_equal false, u.profile.mail_opt_in
  # end
  # 
  # def test_ucd_off_if_signed_up_with_checkbox_missing
  #   post :create, :user => { :login => 'quire@example.com', :email => 'quire@example.com',
  #     :password => 'quire', :password_confirmation => 'quire', :terms_of_service => '1' }
  #   u = User.find(:first, :conditions => {:sage_username => "quire"})
  #   assert !u.nil?
  #   assert_equal false, u.profile.mail_opt_in
  # end
  # 
  
  # TODO: sso -- this functionality needs to be reconciled with sso mechanics
  # def test_signup_with_complete_profile_when_required
  #   get :signup, {:signup_type => "rac"}
  #   assert_difference 'User.count', 1 do
  #     post :create, {:user =>    {:login => 'quire@example.com', :email => 'quire@example.com',
  #                               :password => 'quire', :password_confirmation => 'quire', :terms_of_service => '1' },
  #                    :profile_company_name => "company_name", :profile_contact_name => "contact_name",
  #                    :profile_company_address1 => "company_address1", :profile_company_city => "Vancouver", 
  #                    :profile_company_state => "BC", :profile_company_postalcode => "V1V1V1", :profile_company_phone => "123456789"}
  #   end
  #   u = User.find(:first, :conditions => {:login => 'quire@example.com'})
  #   assert_equal "rac", u.signup_type
  # end
  # 
  # def test_signup_with_incomplete_profile_when_required
  #   get :signup, {:signup_type => "rac"}
  #   assert_no_difference 'User.count' do
  #     create_user
  #   end
  #   assert @response.body.include?("Please fill out all address information")    
  # end
  # 
  # TODO: sso tests for mobile

  # def test_mobile_version_view
  #   get :new, :mobile => 'true'
  #   assert @response.body.include?("mobile version")
  #   assert @response.body.include?("mobile.css")
  #   deny @response.body.include?("shared.css")
  #   deny @response.body.include?("static.css")
  # end
  # 
  # def test_mobile_version_on_invalid_submit
  #   get :new, :mobile => 'true'
  #   post :create, :user => { :login => 'quire@example.com', :email => 'quire@example.com',
  #     :password => 'quire', :password_confirmation => 'quire', :terms_of_service => '0' }
  #   assert @response.body.include?("mobile version")
  #   assert @response.body.include?("errorExplanation")
  #   assert @response.body.include?("mobile.css")
  #   deny @response.body.include?("shared.css")
  #   deny @response.body.include?("static.css")
  # end  
  # 
  
  def test_api_token_should_reset_user_info_after_signup
    # Specific test: create user when already authenticated.
    api_token = ApiToken.new(:mode => 'simply:signup', :user => users(:basic_user), :password => 'test')
    @controller.stubs(:api_token).returns(api_token)
    @controller.stubs(:api_token?).returns(api_token)
    create_user
    assert_response :success
    u = User.find(:first, :conditions => {:sage_username => 'quire'})
    assert api_token.has_user_info?, "api_token should have both user and password."
    assert_equal 'quire', api_token.user.sage_username, 'api_token.user should be the newly created user.'
    assert_equal 'quire@example.com', api_token.user.email, 'api_token.user should be the newly created user.'
  end
    
if ::AppConfig.activate_users   
  def test_should_display_notice_on_invalid_login_on_forgot_password
    User.expects(:find_by_login).with('whatever').returns(nil)
    AccessKey.any_instance.expects(:make_key).never
    UserMailer.expects(:deliver_change_password).never
    get :forgot_password, :login => 'whatever'
    assert_match(/e could not find a user with the email address whatever/, flash[:notice])
    assert_select("input#user_login")    
    assert !assigns(:did_send)
  end
  def test_should_display_notice_on_invalid_login_on_forgot_password
    User.expects(:find_by_login).with('whatever').returns(nil)
    UserMailer.expects(:deliver_signup_notification).never
    get :remail_activation, :login => 'whatever'
    assert_match(/e could not find a user with the email address whatever/, @response.body)
    assert_select("input#user_login")    
    assert !assigns(:did_send)
  end
 
  def test_should_display_notice_on_already_activated_user_on_remail_activation
    assert users(:basic_user).activated?
    User.expects(:find_by_login).with(users(:basic_user).login).returns(users(:basic_user))
    UserMailer.expects(:deliver_signup_notification).never
    get :remail_activation, :login => users(:basic_user).login
    assert_match(/This user is already activated/, @response.body)
    assert_select("input#user_login")
    assert !assigns(:did_send)
  end

  def test_should_remail_activation
    User.expects(:find_by_login).with(users(:unactivated_user).login).returns(users(:unactivated_user))
    UserMailer.expects(:deliver_signup_notification).with(users(:unactivated_user))
    get :remail_activation, :login => users(:unactivated_user).login
    assert_match(/email containing instructions on how to activate your account has been sent to #{users(:unactivated_user).login}/, @response.body)
    assert_select("input#user_login", false)
    assert assigns(:did_send)
  end
end # if AppConfig.activate_users

protected
  def create_user(options = {})
    stub_cas_first_login('quire', 'quire@example.com')
    assert_difference 'User.count', 1 do
      get :thankyou
    end
  end

end
