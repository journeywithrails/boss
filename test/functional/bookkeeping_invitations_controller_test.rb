require File.dirname(__FILE__) + '/../test_helper'

require 'bookkeeping_invitation'
require 'delivery'

class BookkeepingInvitationsControllerTest < ActionController::TestCase
  fixtures :users, :invitations, :deliveries, :bookkeeping_contracts, :roles
  
  def setup
    @controller = BookkeepingInvitationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :bookkeeper_user unless %w{test_should_display_invitation_for_logged_off_user}.include?(method_name)
  end
  
  def teardown
    $log_on = false
  end
  
  def setup_access_key
    @ak = OpenStruct.new(
        :keyable_id => invitations(:invitation_for_unknown_bookkeeper).id,
        :keyable_type => 'Invitation',
        :uses => 99999,
        :used => 0,
        :key => '99999999999999999999999999999999',
        :use? => true
     )

    AccessKey.stubs(:find_by_key).returns(@ak)
  end
  
  def setup_used_access_key
    @ak = OpenStruct.new(
        :keyable_id => invitations(:invitation_for_unknown_bookkeeper).id,
        :keyable_type => 'Invitation',
        :uses => 99999,
        :used => 99999,
        :key => '99999999999999999999999999999999',
        :use? => false
     )

    AccessKey.stubs(:find_by_key).returns(@ak)
  end
  
  def test_should_display_invitation_for_logged_off_user
    stub_cas_logged_out
    setup_access_key
    get :display_invitation, :id => @ak.key
    assert_response :success
    assert_template 'bookkeeping_invitations/invitation_new_user'
  end

  def test_should_display_invitation_logged_in
    setup_access_key

    get :display_invitation, :id => @ak.key
    assert_response :success
    assert_template 'bookkeeping_invitations/display_invitation_logged_in'
  end
  
  def test_should_accept_bookkeeping_invitation
    setup_access_key

    post :accept, :id => @ak.key
    assert invitations(:invitation_for_unknown_bookkeeper).confirmed?
    assert_redirected_to :controller => 'bookkeeping_invitations', :action => 'show'
  end
  
  def test_should_decline_bookkeeping_invitation
    setup_access_key
    
    post :decline, :id => @ak.key
    assert_redirected_to :controller => 'bookkeeping_invitations', :action => 'show'
    assert invitations(:invitation_for_unknown_bookkeeper).declined?
    
    #do not allow multiple declines
    post :decline, :id => @ak.key
    assert_template 'bookkeeping_invitations/failed'
    assert_equal 'Invitation has already been declined.', assigns(:invitation).errors.on_base
    assert invitations(:invitation_for_unknown_bookkeeper).declined?
  end
  
  def test_should_show_accepted_or_confirmed_invitation
    %w{accepted confirmed}.each do |status|
      invitations(:invitation_for_unknown_bookkeeper).status = status
      invitations(:invitation_for_unknown_bookkeeper).save(false)
      get :show, :id => invitations(:invitation_for_unknown_bookkeeper).id
      assert_response :success
      assert_template 'bookkeeping_invitations/accepted'
    end
  end
  
  def test_should_show_declined_invitation
    %w{declined}.each do |status|
      invitations(:invitation_for_unknown_bookkeeper).status = status
      invitations(:invitation_for_unknown_bookkeeper).save(false)
      get :show, :id => invitations(:invitation_for_unknown_bookkeeper).id
      assert_response :success
      assert_template 'bookkeeping_invitations/declined'
    end
  end
  
  
  def test_should_show_error_for_non_accepted_or_confirmed_invitation
    %w{rescinded withdrawn terminated}.each do |status|
      invitations(:invitation_for_unknown_bookkeeper).status = status
      invitations(:invitation_for_unknown_bookkeeper).save(false) # should stub. in a hurry
      get :show, :id => invitations(:invitation_for_unknown_bookkeeper).id
      assert_response :success
      assert_template 'bookkeeping_invitations/error'
      assert_match %r{#{invitations(:invitation_for_unknown_bookkeeper).status_explanation}}, @response.body
    end
  end
    
  def test_should_not_decline_after_confirmed_invitation
    setup_access_key
    
    post :accept, :id => @ak.key
    assert invitations(:invitation_for_unknown_bookkeeper).confirmed?
    assert_redirected_to :controller => 'bookkeeping_invitations', :action => 'show'

    post :decline, :id => @ak.key
    assert_template 'bookkeeping_invitations/failed'
    assert_equal 'Invitation cannot currently be declined.', assigns(:invitation).errors.on_base
  end
  
  def test_should_not_accept_after_accept_invitation
    setup_access_key
    
    post :accept, :id => @ak.key
    assert invitations(:invitation_for_unknown_bookkeeper).confirmed?
    assert_redirected_to :controller => 'bookkeeping_invitations', :action => 'show'

    post :accept, :id => @ak.key
    assert_template 'bookkeeping_invitations/failed'
    assert_equal 'Invitation has already been accepted.', assigns(:invitation).errors.on_base
  end
  
  def test_should_reject_invalid_key
    get :display_invitation, :id => 'invalid key'
    assert_response :not_found
    assert_template 'access/not_found'

    post :accept, :id => 'invalid key'
    assert_response :not_found
    assert_template 'access/not_found'
    
    post :decline, :id => 'invalid key'
    assert_response :not_found
    assert_template 'access/not_found'
    
    stub_cas_logged_out
    get :display_invitation, :id => 'invalid key'
    assert_response :not_found
    assert_template 'access/not_found'
  end
  
#  def test_should_not_allow_get_on_accept_or_decline
#    setup_access_key
#    
#    get :accept, :id => @ak.key
#    assert_template 'bookkeeping_invitations/failed'
#    
#    get :decline, :id => @ak.key
#    assert_template 'bookkeeping_invitations/failed'
#  end

  def test_should_reject_used_up_key
    setup_used_access_key
    
    get :display_invitation, :id => @ak.key
    assert_response :success
    assert_template 'bookkeeping_invitations/failed'

    post :accept, :id => @ak.key
    assert_response :success
    assert_template 'bookkeeping_invitations/failed'
    
    post :decline, :id => @ak.key
    assert_response :success
    assert_template 'bookkeeping_invitations/failed'
    
    stub_cas_logged_out
    get :display_invitation, :id => @ak.key
    assert_response :success
    assert_template 'bookkeeping_invitations/failed'
    puts "@response.body: #{@response.body}" if $log_on
  end
  
  def test_should_create_bookkeeping_invitation_for_bookkeeper_in_system
    assert_difference 'Invitation.count', 1 do
      assert_no_difference 'Delivery.count' do
        get :new, :bookkeeper_id => "1"
      end
    end
    assert_response :success
    assert_template 'deliveries/new'
    assert_not_nil(assigns(:delivery))    
    assert !assigns(:delivery).mail_options[:show_recipients]
    assert_not_nil(assigns(:delivery).deliverable.invitee)
    assert_equal(bookkeepers(:first_bookkeeper).email, assigns(:delivery).recipients)
    # puts @response.body
    assert_select("input#delivery_mail_name[type=hidden][value=send_invitation]")
    assert_select("input#delivery_deliverable_type[type=hidden][value=Invitation]")
    assert_select("input#delivery_deliverable_id[type=hidden][value=#{assigns(:delivery).deliverable_id}]")
    assert_select("input#delivery_recipients[type=text]", false, "recipients should not be editable")
    assert_select("input#delivery_subject[type=text][disabled=disabled]", false, "message subject should be enabled")
    assert_select("textarea#delivery_body[disabled=disabled]", false, "message body should be enabled")
  end

  def test_should_create_bookkeeping_invitation_for_email_to_be_entered
    assert_difference 'Invitation.count', 1 do
      assert_no_difference 'Delivery.count' do
        get :new
      end
    end
    assert_response :success
    assert_template 'deliveries/new'
    assert_not_nil(assigns(:delivery))
    assert assigns(:delivery).mail_options[:show_recipients]
    assert_nil(assigns(:delivery).deliverable.invitee)
    assert assigns(:delivery).recipients.blank?

    assert_select("input#delivery_mail_name[type=hidden][value=send_invitation]")
    assert_select("input#delivery_deliverable_type[type=hidden][value=Invitation]")
    assert_select("input#delivery_deliverable_id[type=hidden][value=#{assigns(:delivery).deliverable_id}]")
    assert_select("input#delivery_recipients[type=text]", true, "recipients should be editable")
    assert_select("input#delivery_subject[type=text][disabled=disabled]", false, "message subject should be enabled")
    assert_select("textarea#delivery_body[disabled=disabled]", false, "message body should be enabled")
  end
  
end
