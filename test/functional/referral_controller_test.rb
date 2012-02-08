require File.dirname(__FILE__) + '/../test_helper'

class ReferralControllerTest < ActionController::TestCase
  fixtures :users
  def setup
    start_email_server
    get :new
    logout
  end
  
  def teardown
    end_email_server
  end
  
  def test_index
    get :index
    assert_response :success
  end

  def test_blank_submission
    assert_no_difference('Referral.count') do
      post :create, :referral => {}
      assert @response.body.include?("You have not invited any friends")
    end
  end

  def test_submission_with_no_friends
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com"}
      assert @response.body.include?("You have not invited any friends")
      assert_select 'input#referral_referrer_name[value=John]'
    end    
  end
  
  def test_submission_with_missing_referrer_name
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert @response.body.include?("You must enter your name and e-mail, and a valid e-mail for each friend you invite")
      assert_select 'input#referral_referrer_email[value=john@abc.com]'
      assert_select 'input#referral_friend_name_1[value=Friend 1]'
      assert_select 'input#referral_friend_email_1[value=friend1@abc.com]'
      assert_select 'th#referrer_name_field_cell[class=error_in_cell]'
    end       
  end
  
  def test_submission_with_missing_referrer_email
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert @response.body.include?("You must enter your name and e-mail, and a valid e-mail for each friend you invite")
      assert_select 'input#referral_referrer_name[value=John]'
      assert_select 'input#referral_friend_name_1[value=Friend 1]'
      assert_select 'input#referral_friend_email_1[value=friend1@abc.com]'
      assert_select 'th#referrer_email_field_cell[class=error_in_cell]'
    end      
  end
  
  def test_submission_with_invalid_referrer_email
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}

      assert @response.body.include?("You must enter your name and e-mail, and a valid e-mail for each friend you invite")
      assert_select 'input#referral_referrer_name[value=John]'
      assert_select 'input#referral_referrer_email[value=john@abc]'
      assert_select 'input#referral_friend_name_1[value=Friend 1]'
      assert_select 'input#referral_friend_email_1[value=friend1@abc.com]'
      assert_select 'th#referrer_email_field_cell[class=error_in_cell]'
    end      
  end
  
  def test_valid_submission_with_missing_friend_name
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_email_1 => "friend1@abc.com"}
     assert_response :redirect
    end      
  end
  
  def test_submission_with_missing_friend_email
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1"}
      assert @response.body.include?("You must enter your name and e-mail, and a valid e-mail for each friend you invite")
      assert_select 'input#referral_referrer_name[value=John]'
      assert_select 'input#referral_referrer_email[value=john@abc.com]'
      assert_select 'input#referral_friend_name_1[value=Friend 1]'
      assert_select 'td#friend_1_email_field_cell[class=error_in_cell]'
    end       
  end
  
  def test_submission_with_invalid_test_email
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc"}
      assert @response.body.include?("You must enter your name and e-mail, and a valid e-mail for each friend you invite")
      assert_select 'input#referral_referrer_name[value=John]'
      assert_select 'input#referral_referrer_email[value=john@abc.com]'
      assert_select 'input#referral_friend_name_1[value=Friend 1]'
      assert_select 'input#referral_friend_email_1[value=friend1@abc]'
      assert_select 'td#friend_1_email_field_cell[class=error_in_cell]'
    end          
  end
  
  def test_valid_submission_with_one_friend
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert_response :redirect
    end    
  end
  
  def test_valid_submission_with_three_friends
    assert_difference('Referral.count', +3) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com",
                                  :friend_name_2 => "Friend 2", :friend_email_2 => "friend2@abc.com",
                                  :friend_name_3 => "Friend 3", :friend_email_3 => "friend3@abc.com"}
      assert_response :redirect
    end           
  end
  
  def test_submission_with_duplicate_friend_emails
    assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com",
                                  :friend_name_2 => "Friend 2", :friend_email_2 => "friend1@abc.com"}

      assert_response :redirect
      r = Referral.find(:all)
      assert r[0].friend_name == "Friend 1"   
    end  
  end
  
  def test_submission_with_friend_email_existing_in_database
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
    assert_response :redirect
    end
    
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 2", :friend_email_1 => "friend1@abc.com"}
            assert_response :redirect
      r = Referral.find(:all)
      assert r[0].friend_name == "Friend 1"
    end
  end
  
  def test_valid_submission_with_skipped_friend
    assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "", :friend_email_1 => "",
                                  :friend_name_2 => "Friend 2", :friend_email_2 => "friend2@abc.com"}
    assert_response :redirect
    end        
  end
  
  def test_submission_with_one_valid_and_one_invalid_friend
    assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com",
                                  :friend_name_2 => "Friend 2", :friend_email_2 => "friend2@abc"}
      assert @response.body.include?("You must enter your name and e-mail, and a valid e-mail for each friend you invite")
      assert_select 'input#referral_referrer_name[value=John]'
      assert_select 'input#referral_referrer_email[value=john@abc.com]'
      assert_select 'input#referral_friend_name_1[value=Friend 1]'
      assert_select 'input#referral_friend_email_1[value=friend1@abc.com]'
      assert_select 'input#referral_friend_name_2[value=Friend 2]'
      assert_select 'input#referral_friend_email_2[value=friend2@abc]'
      assert_select 'td#friend_2_email_field_cell[class=error_in_cell]'
    end        
  end
  
  def test_submission_with_one_valid_friend_and_one_friend_with_duplicate_email_in_database
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
    
      assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1A", :friend_email_1 => "friend1@abc.com",
                                  :friend_name_2 => "Friend 2", :friend_email_2 => "friend2@abc.com"}

      assert_response :redirect 
    end  
  end
  
  def test_invitation_of_already_accepted_friend
      assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      end
      
      r = Referral.find(:first, :conditions => {:referring_email => "john@abc.com"})
      r.accepted_at = Time.now
      r.save!
      
      assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "Bob", :referrer_email => "bob@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      end      
  end
  
  def test_invitation_exceeding_mailer_limit
      assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      end
      
      assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john2@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      end      

      assert_no_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john3@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      end
      
      r = Referral.find(:first, :conditions => {:referring_email => "john2@abc.com"})
      r.sent_at = Time.now-1.day
      r.save!

      assert_difference('Referral.count', +1) do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john3@abc.com",
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      end
      
  end
  
  def test_soho_user_logged_out
    get :new
    assert_select "span#soho_text"
    assert_select "span#ssan_test", 0
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert_response :redirect
    end
    r = Referral.find(:all)
    assert r[0].referring_type == "soho"
  end
  
  def test_ssan_user_logged_out
    get :new, {:signup_type => "ssan"}
    get :new
    assert_select "span#ssan_text"
    assert_select "span#soho_test", 0
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert_response :redirect
    end
    r = Referral.find(:all)
    assert r[0].referring_type == "ssan"    
  end

  def test_soho_user_logged_in_as_soho
    login_as :soho_user
    get :new
    get :new
    assert_select "span#soho_text"
    assert_select "span#ssan_test", 0
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert_response :redirect
    end
    r = Referral.find(:all)
    assert r[0].referring_type == "soho"
  end
  
  def test_rac_referral
    get :new, :signup_type => "rac"
    assert_difference('Referral.count') do
      post :create, :referral => {:referrer_name => "John", :referrer_email => "john@abc.com", 
                                  :friend_name_1 => "Friend 1", :friend_email_1 => "friend1@abc.com"}
      assert_response :redirect
    end
    r = Referral.find(:all)
    assert r[0].referring_type == "rac"    
    
  end
  
  def test_accepted
    get :accepted
    assert_response :success
    assert @response.body.include?("spread the word")
  end
  

  
end
