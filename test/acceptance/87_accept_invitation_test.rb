$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# acceptance test for user story 87
# accept bookkeeper invitation
# an invitation will be generated from code
# the key will be used to navigate to the acceptance link rather
# than click a link in an email that would be the normal procedure

# the test cases will be:
#   a) the invited bookkeeper creates an account
#   b) the invited bookkeeper has an account and signs on
#   c) the invited bookkeeper is already signed on

class AcceptBookkeepingInvitation < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invitations, :bookkeepers, :bookkeeping_contracts, :roles
  
  def setup
    @browser = watir_session
    unless stubbing_cas?
      SSO::SAM.prepare(true)
    end
    @biller_user = users(:wants_bookkeeper_user)
    @bookkeeper_user = users(:bookkeeper_user)
    @debug = false
  end
  
  def teardown
    User.delete_all(:sage_username => "new_bk_user")
    @browser.teardown
  end
 
  def test_new_user_accepts_invitation
    ensure_user_logged_out
    user_creates_invitation_for(:new_user)
    set_paths
    # ensure_user_logged_out
    # exit unless $test_ui.agree("user has stubbed logged out?", true)

    # 1. display_invitation page
    goto_access_path
    exit unless $test_ui.agree("shiny register button?", true) if @debug      
    assert @browser.link(:text, /new account/).exists?, "when not logged in, display invitation page should have a 'new account' link"
    assert_sam_url_with_service(
      %r{bookkeeping_invitations/display_invitation/#{@access_key}}, 
      @browser.link(:text, /new account/).href)

    assert @browser.button(:id,"large-register-button").exists?, "should also have a shiny button for registering"

    

    # 2. signup for account
    assert_difference 'User.count' do
      click_new_account_link("new_bk_user", "new_bk_user@test.com")
      signup_for_new_account("new_bk_user", "new_bk_user@test.com")
      Watir::Waiter.new(12).wait_until do
         @browser.button(:value, "Accept").exists?
      end
    end    
    
    # 3. display_invitation page
    assert_on_diplay_invitation_page
    assert_page_contains_invitor_name
    assert @browser.button(:value, "Accept").exists?
    assert_difference 'Bookkeeper.count' do
      assert_difference 'Role.count' do        
        assert_difference 'BookkeepingContract.count' do
          @browser.button(:value, "Accept").click
        end
      end
    end    

    check_invitation_accepted("You now have access to ")

    click_on_billers_link

    bookkeeper_user = User.find(:first, :conditions => ["sage_username = ?", "new_bk_user"])
    
    check_client_data(bookkeeper_user) 
    
    
  end

  def test_existing_bookkeeper_accepts_invitation
    user_creates_invitation_for(@bookkeeper_user.email)
    exit unless $test_ui.agree("invitation?", true) if @debug
    set_paths
    ensure_user_logged_out
    # exit unless $test_ui.agree("user has stubbed logged out?", true)

    goto_access_path    

    exit unless $test_ui.agree("ready to login?", true) if @debug
    assert @browser.button(:id,"large-login-button").exists?
    assert @browser.link(:id, 'inline-login-link').exists?
    
    login_from_invitation_as_user(@bookkeeper_user)
    
    Watir::Waiter.new(12).wait_until do
       @browser.button(:value, "Accept").exists?
    end
    
    # accept invitation
    assert_no_difference 'User.count' do
      assert_no_difference 'Bookkeeper.count' do
        assert_difference 'Role.count' do
          assert_difference 'BookkeepingContract.count' do
            @browser.button(:value, "Accept").click
          end
        end
      end    
    end
    exit unless $test_ui.agree("check roles?", true) if @debug
    check_invitation_accepted("You now have access to ")    
    assert_page_contains_invitor_name
    click_on_billers_link
    check_client_data(@bookkeeper_user)
    
    
    
  end

  def test_existing_user_accepts_invitation
    existing_user = users(:basic_user)    
    user_creates_invitation_for(existing_user.email)
    set_paths
    
    ensure_user_logged_out
    
    goto_access_path   

    exit unless $test_ui.agree("ready to login?", true) if @debug
    assert @browser.button(:id,"large-login-button").exists?
    assert @browser.link(:id, 'inline-login-link').exists?
    
    login_from_invitation_as_user(users(:basic_user))
    
    Watir::Waiter.new(12).wait_until do
       @browser.button(:value, "Accept").exists?
    end

    assert_no_difference 'User.count' do
      assert_difference 'Bookkeeper.count' do
        assert_difference 'Role.count' do
          assert_difference 'BookkeepingContract.count' do
            @browser.button(:value, "Accept").click
          end
        end
      end    
    end
    
    exit unless $test_ui.agree("check roles, bookkeeper etc?", true) if @debug
    check_invitation_accepted("You now have access to ")   
    assert_page_contains_invitor_name
    click_on_billers_link
  
    # reload user record because bookkeeper id has changed
    existing_user = User.find(existing_user.id)
    
    check_client_data(existing_user)
    
    
  end

  def test_logged_on_bookkeeper_accepts_invitation
    ensure_user_logged_out
    login_as_user(@bookkeeper_user)
    user_creates_invitation_for(@bookkeeper_user.email)
    set_paths
        
    goto_access_path
    
    Watir::Waiter.new(12).wait_until do
       @browser.button(:value, "Accept").exists?
    end

    assert_no_difference 'User.count' do
      assert_no_difference 'Bookkeeper.count' do
        assert_difference 'Role.count' do
          assert_difference 'BookkeepingContract.count' do
            @browser.button(:value, "Accept").click
          end
        end
      end    
    end
    
    check_bookkeeping_invitation_accepted   
    
    click_on_billers_link 
    check_client_data(@bookkeeper_user)
    
    
  end
  
  def test_logged_on_bookkeeper_declines_invitation
    ensure_user_logged_out
    login_as_user(@bookkeeper_user)
    user_creates_invitation_for(@bookkeeper_user.email)
    set_paths
        
    goto_access_path

    assert_no_difference 'User.count' do
      assert_no_difference 'Bookkeeper.count' do
        assert_no_difference 'Role.count' do
          assert_no_difference 'BookkeepingContract.count' do
            @browser.button(:value, "Decline").click
          end
        end
      end    
    end
    
    check_bookkeeping_invitation_declined
    
    
  end

private  
  def user_creates_invitation_for(email)
    assert_difference 'Invitation.count' do    
      @invitation = @biller_user.invitations.create()
      @invitation.type = 'BookkeepingInvitation'
      @invitation.status = 'sent'
      unless email == :new_user
        d = @invitation.deliveries.create()
        d.recipients = email
      end
      @invitation.save(false)
      assert_difference 'AccessKey.count' do
        @access_key = @invitation.create_access_key
        exit unless $test_ui.agree("access_key?", true) if @debug
      end
    end
  end
  
  def set_paths
    @billingboss_url = @browser.site_url + '/'
    @accessPath = @billingboss_url + "access/" + @access_key
    @invitationPath = @billingboss_url + "bookkeeping_invitations/display_invitation/" + @access_key
    @signupPath = @billingboss_url + "signup?back=1"
    @invitationAcceptPath = @billingboss_url + "invitations/" + @access_key + "/accept" #/invitations/:id/accept
    @bookkeepingInvitationsAcceptPath = @billingboss_url + "bookkeeping_invitations/show/" + @invitation.to_param
    @bookkeepingInvitationsDeclinePath = @billingboss_url + "bookkeeping_invitations/show/" + @invitation.to_param
  end
  
  def goto_access_path
    @browser.goto(@accessPath)
    exit unless $test_ui.agree("on invitations page?", true) if @debug
    # verify we are on the invitations page
    assert_equal "Bookkeeping invitations: display_invitation", @browser.title    
    assert_on_diplay_invitation_page
    assert_page_contains_invitor_name    
  end
  
  def assert_on_diplay_invitation_page
    assert_match %r{#{@invitationPath}}, @browser.url, "should be on display_invitation page"
  end
  
  def assert_page_contains_invitor_name
    # check that the inviting biller's name is on the page
    Watir::Waiter.new(12).wait_until do
       @browser.span(:id, 'invitor_name').exists?
    end
    invitor_name = @biller_user.profile.company_name || @biller_user.sage_username
    assert_match @browser.span(:id, 'invitor_name').text, invitor_name   
  end
  
  def check_invitation_accepted(message)
    exit unless $test_ui.agree("on accepted page?", true) if @debug
    assert_equal @bookkeepingInvitationsAcceptPath, @browser.url     
    #look for the flash message to see if the account is created or logged in 
    assert_not_nil @browser.contains_text(message)

    assert_page_contains_invitor_name    
  end

  def check_bookkeeping_invitation_accepted
    @browser.wait
    assert_equal @bookkeepingInvitationsAcceptPath, @browser.url     
    assert_page_contains_invitor_name    
  end
  
  def check_bookkeeping_invitation_declined
    @browser.wait
    assert_equal @bookkeepingInvitationsDeclinePath, @browser.url     
  end
  
  
  def click_on_billers_link
    exit unless $test_ui.agree("click view client info?", true) if @debug
    assert @browser.link(:text, "View client information.").exists?
    assert_equal "/tabs/bookkeeper", @browser.link(:text, "View client information.").href
    @browser.link(:text, "View client information.").click

    exit unless $test_ui.agree("click View Client's Data?", true) if @debug
    assert @browser.link(:href, bookkeepingClientPath(@biller_user.biller_id)).exists?
    @browser.link(:href, bookkeepingClientPath(@biller_user.biller_id)).click    

    exit unless $test_ui.agree("click Invoice Report?", true) if @debug
    assert @browser.link(:text, "Invoice Report").exists?
    assert @browser.link(:text, "Payment Report").exists?
    
    assert_equal bookkeepingClientPath(@biller_user.biller.id.to_s)+'invoice', @browser.link(:text, "Invoice Report").href
    assert_equal bookkeepingClientPath(@biller_user.biller.id.to_s)+'payment', @browser.link(:text, "Payment Report").href
    @browser.link(:text, "Invoice Report").click

    assert_equal bookkeepingClientPath(@biller_user.biller.id.to_s, true)+"invoice", @browser.url 
  end
  
  def bookkeepingClientPath(billerId, absolute = false)
    url = absolute ? @billingboss_url : '/'
    url + "bookkeeping_clients/" + billerId.to_s + "/reports/"   
  end
  
  def check_client_data(bookkeeper_user)
    bookkeeper = Bookkeeper.find(bookkeeper_user.bookkeeper_id)
    client = bookkeeper.bookkeeping_clients.find(@biller_user.biller.id)
    client_name = (client.profile.company_name.blank? ? client.email : client.profile.company_name)
    assert_match client_name, @browser.div(:id, 'invoice_report_grid').span(:class, 'x-panel-header-text').text
    
  end
  
  def logout
    @browser.logs_out
    @browser.wait
  end
  
  def click_new_account_link(username, email)
    sam_url = @browser.link(:text, /new account/).href
    service_url = sam_service_url_from_redirect_url(sam_url)
    if stubbing_cas?
      @browser.stub_first_login(username, email)
      @browser.goto service_url
    else
      @browser.link(:text, /new account/).click
    end    
  end

  def signup_for_new_account(username, email)
    unless stubbing_cas?
      @browser.with_sage_user("new_bk_user")
      assert_on_bb_signup_page(@browser)
      user_fills_in_sam_signup_form(@browser, :username => username, :email => email)
      exit unless $test_ui.agree('click register on sam?', true) if @debug
      @browser.button(:id, "register_button").click
    end
  end
  
  def login_as_user(user)
    if stubbing_cas?
      @browser.stub_logged_in(user.sage_username)
    else
      @browser.with_sage_user(user.sage_username)
      assert_click_goto_bb_and_click_login(@browser, @debug)
      assert_cas_login(@browser, @debug)
    end
  end

  def login_from_invitation_as_user(user)
    if stubbing_cas?
      @browser.stub_logged_in(user.sage_username)
      goto_access_path    
    else
      @browser.with_sage_user(user.sage_username)
      @browser.button(:id,"large-login-button").click

      # login 
      exit unless $test_ui.agree("enter credentials?", true) if @debug
      assert_cas_login(@browser)
      
      Watir::Waiter.new(12).wait_until do
         @browser.title == "Bookkeeping invitations: display_invitation"
      end      
      assert_on_diplay_invitation_page
      assert_page_contains_invitor_name    
    end
  end
  
  def ensure_user_logged_out
    if stubbing_cas?
      @browser.is_logged_out
    else
      @browser.logs_out_cas
    end
  end
  
  def stubbing_cas?
    true
  end
 end
