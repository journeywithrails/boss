require File.dirname(__FILE__) + '/../test_helper'

class ContestControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  fixtures :users
  def setup
    @controller = ContestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
if ::AppConfig.contest.bybs
  def test_contest_tabs_test
    get :index
    assert_select "li[class=link1_current]"
    assert_select "li[class=link2]"
    assert_select "li[class=link2_current]", 0
    
    get :tell_a_friend
    assert_select "li[class=link2_current]"
    assert_select "li[class=link1]"
    assert_select "li[class=link1_current]", 0
    
    get :signup
    assert_select "li[class=link1_current]", 0
    assert_select "li[class=link2_current]", 0
    assert_select "li[class=link2]"
    assert_select "li[class=link2]"
  end
  
  def test_contest_front_page
    get :index
    assert @response.body.include?("href=\"/contest/signup\"")  
  end

  def test_contest_signup_renders_with_correct_layout
    logout
    get :signup
    assert_select "div#doc2[class=yui-t7]"
    assert @response.body.include?("/contest/btn_signup.gif")
  end
  
  def test_contest_taf_renders_with_correct_layout
    get :tell_a_friend
    assert_select "div#doc2[class=yui-t7]"
    assert_select "input#referral_referrer_name"
    
    login_as :basic_user
    get :tell_a_friend
    assert_select "div#doc2[class=yui-t7]"
    assert_select "input#referral_referrer_name"
    assert @response.body.include?("/images/btn_send_now.gif")
  end
  
  def test_taf_accepted
    get :tell_a_friend_accepted
    assert_response :success
    assert @response.body.include?("spread the word")
  end
  
  def test_tour
    get :tour
    assert_response :success
    assert @response.body.include?("Watch our video")
  end
  
  def test_winners
    w = Winner.new
    w.signup_type = "ssan"
    w.draw_date = Date.today
    w.winner_name = "John Smith"
    w.prize = "Monitor"
    w.save!
    
    w2 = Winner.new
    w2.signup_type = "soho"
    w2.draw_date = Date.today
    w2.winner_name = "Mary Doe"
    w2.prize = "Flash Memory"
    w2.save!
    
    get :winners, :signup_type => "soho"
    assert @response.body.include?("Mary")
    deny @response.body.include?("John")
    
    get :winners, :signup_type => "ssan"
    assert @response.body.include?("John")
    deny @response.body.include?("Mary")
  end
end
end
