require "#{File.dirname(__FILE__)}/../test_helper"

class SignupBrowsalTest < ActionController::IntegrationTest
  include SimplyApiTestHelpers

  def test_should_create_user_and_update_browsal
    RAILS_DEFAULT_LOGGER.debug("-------------------- 1 -----------------")
    
    assert_nil User.find_by_sage_username('brand_new_user')
    api_token, current_url, token_url = initiate_signup('signup')
    extended_session do |user|
      RAILS_DEFAULT_LOGGER.debug("-------------------- 2 -----------------")
      user.signup_page!(current_url)
      RAILS_DEFAULT_LOGGER.debug("-------------------- 3 -----------------")
      assert_difference 'Biller.count' do
        assert_difference 'User.count' do 
          RAILS_DEFAULT_LOGGER.debug("-------------------- 4 -----------------")
          user.signup!
          RAILS_DEFAULT_LOGGER.debug("-------------------- 5 -----------------")
        end
      end
    end
# NOTE: the browsal show action has not been implemented since I beleive it is unused
#   get browsal_location, :format => 'xml'
#   assert_response :success 
#   xmlBody = REXML::Document.new(@response.body)
#   assert REXML::XPath.first(xmlBody, '/signup-browsal')
#   assert REXML::XPath.first(xmlBody, '/signup-browsal/guid')
#   assert REXML::XPath.first(xmlBody, '/signup-browsal/id')
#   assert REXML::XPath.first(xmlBody, '/signup-browsal/created-by-id')
#   assert REXML::XPath.first(xmlBody, '/signup-browsal/user')
#   assert REXML::XPath.first(xmlBody, '/signup-browsal/user/login')
#   assert REXML::XPath.first(xmlBody, '/signup-browsal/user/password')
#   
#   assert_equal id, REXML::XPath.first(xmlBody, '/signup-browsal/id').text, "expecting the browsal id to be #{id}"      
#   user_login = REXML::XPath.first(xmlBody, '/signup-browsal/user/login').text    
#   assert_equal browsal.created_by.login, user_login, 'the user login should equal created-by-login' 
#   assert_equal 'test@example.com', REXML::XPath.first(xmlBody, '/signup-browsal/user/login').text, "expecting the user login to be test@example.com"
    
  end
end
