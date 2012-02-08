require "#{File.dirname(__FILE__)}/../test_helper"

class AcceptBookkeepingInvitationTest < ActionController::IntegrationTest
  fixtures :users, :bookkeepers, :billers, :invitations, :bookkeeping_contracts, :roles, :roles_users
  
  def setup
    @biller_user = users(:wants_bookkeeper_user)
    @bookkeeper_user = users(:bookkeeper_user)

    @biller = test_session
    @bookkeeper = test_session
    unstub_cas
    stub_cas_check_status
  end
  
  def teardown
    
  end
  
  def test_new_user_accepts_invitation
    user_creates_invitation


    @bookkeeper.access_invitation_as(:none)
    @bookkeeper.assert_page_has_invitors_name(@biller_user)
    return_from_signup_path = @bookkeeper.assert_has_signup_link


    stub_cas_first_login("new_bookkeeper", "new_bookkeeper@billingboss.com")
    
    assert_difference 'User.count', 1, "A User should be created" do
      @bookkeeper.get return_from_signup_path 
    end

    accept_path = @bookkeeper.assert_on_accept_page_and_get_accept_link
    
    assert_difference 'Bookkeeper.count', 1, "A Bookkeeper should be created" do
      assert_difference 'Role.count', 1, "A Role should be created" do        
        assert_difference 'BookkeepingContract.count', 1, "A BookkeepingContract should be created" do
          @bookkeeper.post_via_redirect accept_path
        end
      end
    end    
    
    puts @bookkeeper.response.body if $debug

    @bookkeeper.assert_invitation_accepted(@biller_user)
    biller_link = @bookkeeper.assert_biller_link(@biller_user)

    @bookkeeper.get_via_redirect biller_link
    puts @bookkeeper.response.body if $debug
    @bookkeeper.assert_select("td", {:text => @biller_user.sage_username})
    # bookkeeper_user = User.find(:first, :conditions => ["login = ?", "new_user01@test.com"])
    # 
    # check_client_data(bookkeeper_user) 
    # 
    # 
  end

  def test_existing_bookkeeper_accepts_invitation
    user_creates_invitation
(@bookkeeper_user.email)
    assert_no_difference 'User.count' do
      @bookkeeper.access_invitation_as(@bookkeeper_user)
      @bookkeeper.assert_page_has_invitors_name(@biller_user)    
      accept_path = @bookkeeper.assert_on_accept_page_and_get_accept_link

    # accept invitation
      assert_no_difference 'Bookkeeper.count' do
        assert_difference 'Role.count' do
          assert_difference 'BookkeepingContract.count' do
            puts "click accept" if $debug
            @bookkeeper.post_via_redirect accept_path
          end
        end
      end    
    end

    puts @bookkeeper.response.body if $debug

    @bookkeeper.assert_invitation_accepted(@biller_user)
    biller_link = @bookkeeper.assert_biller_link(@biller_user)

    @bookkeeper.get_via_redirect biller_link
    @bookkeeper.assert_select("td", {:text => @biller_user.sage_username})
    
    # check_client_data(@bookkeeper_user)



  end

  def test_existing_user_accepts_invitation
    existing_user = users(:basic_user)    
    user_creates_invitation
(existing_user)

    assert_no_difference 'User.count' do
      @bookkeeper.access_invitation_as(existing_user)
      @bookkeeper.assert_page_has_invitors_name(@biller_user)
      accept_path = @bookkeeper.assert_on_accept_page_and_get_accept_link

    # accept invitation
      assert_difference 'Bookkeeper.count' do
        assert_difference 'Role.count' do
          assert_difference 'BookkeepingContract.count' do
            puts "click accept" if $debug
            @bookkeeper.post_via_redirect accept_path
          end
        end
      end    
    end

    puts @bookkeeper.response.body if $debug

    @bookkeeper.assert_invitation_accepted(@biller_user)
    biller_link = @bookkeeper.assert_biller_link(@biller_user)

    @bookkeeper.get_via_redirect biller_link
    @bookkeeper.assert_select("td", {:text => @biller_user.sage_username})

  end

  def test_logged_on_bookkeeper_accepts_invitation
    # with stubbed cas this is the same as test_existing_bookkeeper_accepts_invitation
  end

  def test_logged_on_bookkeeper_declines_invitation
    stub_cas_logged_in(users(:bookkeeper_user))
    
    user_creates_invitation
(@bookkeeper_user.email)
    assert_no_difference 'User.count' do
      @bookkeeper.access_invitation_as(@bookkeeper_user, true)    
      @bookkeeper.assert_page_has_invitors_name(@biller_user)
      decline_path = @bookkeeper.assert_on_accept_page_and_get_decline_link
      puts "decline_path: #{decline_path.inspect}" if $debug
      assert_no_difference 'Bookkeeper.count' do
        assert_no_difference 'Role.count' do
          assert_no_difference 'BookkeepingContract.count' do
            @bookkeeper.post_via_redirect decline_path
          end
        end
      end    
    end

    puts @bookkeeper.response.body if $debug
    @bookkeeper.assert_page_has_invitors_name(@biller_user)

    @bookkeeper.assert_declined_invitation


  end

private  
  def user_creates_invitation(email=nil)
    assert_difference 'Invitation.count' do    
      if email.nil?
        @invitation, @access_key = create_invitation(@biller_user)    
      else
        @invitation, @access_key = create_invitation_with_delivery(@biller_user, email)            
      end
    end
    @bookkeeper.access_key = @biller.access_key = @access_key
    @bookkeeper.invitation = @biller.invitation = @invitation
  end

  def create_invitation(user)
    bki = user.invitations.create()
    bki.type = 'BookkeepingInvitation'
    bki.status = 'sent'
    bki.save(false)
    return [bki, bki.create_access_key]
  end

  def create_invitation_with_delivery(user, email)
    bki = user.invitations.create()
    bki.type = 'BookkeepingInvitation'
    bki.status = 'sent'
    d = bki.deliveries.create()
    d.recipients = email
    bki.save(false)
    return [bki, bki.create_access_key]
  end  

  def bookkeepingClientPath(billerId)
    "bookkeeping_clients/" + billerId.to_s + "/reports/"   
  end

  def check_client_data(bookkeeper_user)
    bookkeeper = Bookkeeper.find(bookkeeper_user.bookkeeper_id)
    client = bookkeeper.bookkeeping_clients.find(@biller_user.biller.id)
    client_name = (client.profile.company_name.blank? ? client.email : client.profile.company_name)
    assert_match client_name, @bookkeeper.div(:id, 'invoice_report_grid').span(:class, 'x-panel-header-text').text

  end

  def test_session
    open_session do |sess|
      sess.extend(InvitationTestHelper)
      sess.extend(CasTestHelper) # o_o
      sess.extend(SamTestHelper)
    end
  end

end

module InvitationTestHelper
  attr_accessor :access_key, :invitation
  def access_path
    "access/" + @access_key
  end

  def display_invitation_path
    "bookkeeping_invitations/display_invitation/" + @access_key
  end
  
  def accept_invitation_path
    "invitations/" + @access_key + "/accept" #/invitations/:id/accept
  end

  def accept_bookkeeping_invitation_path
    "bookkeeping_invitations/accept/" + @access_key
  end
  
  def decline_bookkeeping_invitation_path
    "bookkeeping_invitations/decline/" + @access_key    
  end
  
  def access_invitation_as(user=nil, logged_on=false)
    unless logged_on
      get access_path
      assert_redirected_to display_invitation_path
      follow_redirect!
      assert_redirected_to_cas_login
      assert_cas_service_url_matches %r{#{display_invitation_path}}
    
      if user == :none
        stub_cas_logged_out
      else
        stub_cas_logged_in(user)
      end
    end
    
    get access_path
    assert_redirected_to display_invitation_path
    follow_redirect!

    puts "after follow redirect:\n#{@response.body}" if $debug
    # verify we are on the invitations page
    assert_select 'title', "Bookkeeping invitations: display_invitation"
  end

  def assert_has_signup_link
    signup_link_arr = css_select 'a#signup-link'
    assert !signup_link_arr.empty?, "page should have had a signup link"
    signup_link = signup_link_arr.first.attributes['href']
    assert_sam_url_with_service(Regexp.new(Regexp.quote(display_invitation_path)), signup_link)
    service_uri = URI.parse(sam_service_url_from_redirect_url(signup_link))
    service_uri.path
  end
  
  def assert_page_has_invitors_name(biller_user)
    invitor_name = biller_user.profile.company_name || biller_user.sage_username
    assert_select "span#invitor_name", {:text => invitor_name}, "span with invitors name should be on page"
  end
  
  def assert_invitation_accepted(biller_user)
    assert_page_has_invitors_name(biller_user)
    assert @response.body.include?("You now have access to ")
    assert invitation.confirmed?
  end
  
  def assert_biller_link(biller_user)
    biller_link = css_select "a[id=biller-link]"
    deny biller_link.empty?, "page should have link to biller"
    biller_link = biller_link.first.attributes['href']
    puts "biller_link: #{biller_link.inspect}" if $debug
    biller_link
  end
  
  def assert_on_accept_page_and_get_decline_link
    assert_select "input[value=Decline]"
    assert_select "form[action=?]", %r{/bookkeeping_invitations/decline/.*}
    decline_form = css_select "form[action=?]", %r{/bookkeeping_invitations/decline/#{access_key}}
    deny decline_form.empty?, "accept page should have a form with action bookkeeping_invitations/decline/[access_key]"    
    puts response.body if $debug
    decline_path = decline_form.first.attributes['action']
  end

  def assert_on_accept_page_and_get_accept_link
    assert_select "input[value=Accept]"
    assert_select "form[action=?]", %r{/bookkeeping_invitations/accept/.*}
    accept_form = css_select "form[action=?]", %r{/bookkeeping_invitations/accept/#{access_key}}
    deny accept_form.empty?, "accept page should have a form with action bookkeeping_invitations/accept/[access_key]"    
    puts @response.body if $debug
    accept_path = accept_form.first.attributes['action']
  end

  def assert_declined_invitation
    assert @response.body.include?("You declined the invitation from")
    assert invitation.declined?
  end
  
end
