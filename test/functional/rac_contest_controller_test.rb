require File.dirname(__FILE__) + '/../test_helper'

class RacContestControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  fixtures :users
  def setup
    @controller = RacContestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
if ::AppConfig.contest.rac
  def test_contest_tabs_test_index
    get :index
    assert_select "li[class=link1_current]"
    assert_select "li[class=link2]"
    assert_select "li[class=link2_current]", 0
  end
  def test_contest_tabs_test_enter
    get :enter
    assert_select "li[class=link2_current]"
    assert_select "li[class=link1]"
    assert_select "li[class=link1_current]", 0

    get :login
    assert_select "li[class=link2_current]",0
    assert_select "li[class=link1_current]", 0
    
    get :tell_a_client
    assert_select "li[class=link3_current]"    
    
    get :tell_a_client_accepted
    assert_select "li[class=link3_current]", 0    

    get :tour
    assert_select "li[class=link4_current]"  
    
    get :rules
    assert_select "li[class=link5_current]"  
    
  end
  
  def test_contest_front_page
    get :index
    assert @response.body.include?("Easily create")
  end
  
  def contest_tell_a_client_page
    get :tell_a_client
    assert @response.body.include?("Send your clients")
  end
end
end
