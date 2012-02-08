require "#{File.dirname(__FILE__)}/../test_helper"
class UserSignupTest < ActionController::IntegrationTest
  
  fixtures :users
  
  def setup
    u = User.find(users(:basic_user))
    bki = u.invitations.create()
    bki.type = 'BookkeepingInvitation'
    bki.status = 'sent'
    bki.save
    key = bki.create_access_key
    
    @access_url = "access/#{key}"
  end
  
  def teardown
  end
  
  
  def test_should_detect_and_record_fr_canada_post

    user = new_user(:sage_username => 'signup_test', :email => 'signup_test@test.com')
    
    user.signs_up(true, {:r_id => '10'})
    u = User.find(:first, :conditions => {:sage_username => 'signup_test'})
    assert_equal "fr_canada_post", u.profile.heard_from
  end

  def test_not_trigger_on_wrong_r_id
    user = new_user(:sage_username => 'signup_test', :email => 'signup_test@test.com')
    
    user.signs_up(true, {:r_id => '11'})
    u = User.find(:first, :conditions => {:sage_username => 'signup_test'})

    assert_not_equal "fr_canada_post", u.profile.heard_from
  end

  def new_user(options)
    user = open_session do |user|
      user.extend(CasTestHelper)
      def user.scratch
        @scratch ||= OpenStruct.new
      end

      def user.signs_up(terms=false, options={})
        get '/signup', options
        stub_cas_first_login(scratch.options[:sage_username], scratch.options[:email])
        assert_difference 'User.count', 1 do
          get 'newuser/thankyou'
        end
      end
      
    end
    user.scratch.options = options
    user
  end
  
end
