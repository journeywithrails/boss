  require File.dirname(__FILE__) + '/../test_helper'
require 'profiles_controller'

require 'logo'

# Re-raise errors caught by the controller.
class ProfilesController; def rescue_action(e) raise e end; end

class ProfilesControllerTest < Test::Unit::TestCase
  fixtures :users
  fixtures :configurable_settings
  #include ConfigurableSettings
  
  def setup
    @controller = ProfilesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :basic_user
    @controller.stubs(:form_authenticity_token).returns('whateverzzz')
  end

  def test_should_save_time_zone
    login_as :user_without_profile
    put :update, :profile => {:time_zone => 'Africa/Johannesburg'}
    assert_response :success
    profile = users(:user_without_profile).profile
    assert_equal 0, profile.errors.length
  end
  
  def test_should_create_profile
    addr1 = "12"
    addr2 = "333"
    
    login_as :user_without_profile
    #test if user profile gets saved
    @basic_user = users(:user_without_profile)
   
    put :update, :profile => {:company_address1=>addr1, :company_address2=>addr2 }
    
    @user = User.find(@basic_user.id)
    
    #read information saved
    assert_equal @basic_user.id, @user.id
    
    profile = Profile.new(@user)
     
    profile.paypal_password = "setting1value"
    assert_equal "setting1value",profile.paypal_password

    assert_equal addr1, profile.company_address1
    assert_equal addr2, profile.company_address2
    
    assert_response :success
  end

  def test_should_show_profile
    get :edit
    assert_response :success
  end
  
 
unless ENV['OFFLINE']  # skip if OFFLINE
  def test_should_create_new_logo

    fdata = fixture_file_upload('/files/missing_image.gif', 'image/gif')

    assert_difference 'Logo.count', 2 do
      put :update, :logo => { :uploaded_data => fdata}, :html => { :multipart => true }
    end

    assert_response :success
    assert users(:basic_user).logo
    assert_match /missing_image/, users(:basic_user).logo.public_filename 

  rescue SocketError
    # offline
  end
  
  def test_should_edit_and_delete_logo
    fdata = fixture_file_upload('/files/missing_image.gif', 'image/gif', :binary)
    assert_difference 'Logo.count', 2 do
      put :update, :logo => {:uploaded_data => fdata}, :html => { :multipart => true }
    end

    assert_response :success
    users(:basic_user).reload
    assert users(:basic_user).logo
    users(:basic_user).logo.reload
    
    
    assert_match /missing_image/, users(:basic_user).logo.public_filename 

    fdata = fixture_file_upload('/files/missing_image_2.gif', 'image/gif')
    assert_no_difference 'Logo.count' do
      put :update, :logo => {:uploaded_data => fdata}, :html => { :multipart => true }
    end

    assert_response :success
    assert users(:basic_user).logo
    users(:basic_user).logo.reload
    
    assert_match /missing_image_2/, users(:basic_user).logo.public_filename 
    
    assert_difference 'Logo.count', -2 do
      put :update, :logo => { :delete => 1 }, :html => { :multipart => true }
    end

    assert_response :success
    users(:basic_user).logo.reload
    assert_nil users(:basic_user).logo

  rescue SocketError
    # offline
  end
end # skip if OFFLINE
  
  def test_should_save_numeric_tax_rate
    #TODO: test that bad values are not stored
    #TODO: test that profile errors get cleared between #puts ???
    #TODO: Creating a new Profile object every time the profile is requested... is that right?
    
    login_as :user_without_profile
    put :update, :profile => {:tax_1_name => 'wonderful tax', :tax_1_rate => " \t5.5"  }
    assert_response :success
    profile = users(:user_without_profile).profile
    assert_equal 0, profile.errors.length 
  end
     
     
  def test_error_negative_rate
    
    login_as :user_without_profile

    put :update, :profile => {:tax_2_name => 'better tax', :tax_2_rate => '-5'  }
    assert_response :success
    profile = assigns(:profile)
    assert_equal 1, profile.errors.length 
    assert_equal "must be a number. Please enter a valid number greater than 0.", profile.errors.on(:tax_2_rate)
      
  end

  def test_rate_must_be_numeric
    
    login_as :user_without_profile

    # test rate must be a number when name is not blank
      put :update, :profile => {:tax_1_name => 'best tax', :tax_1_rate => 'stuff'  }
      assert_response :success
      assert_equal 'must be a number. Please enter a valid number greater than 0.', assigns(:profile).errors.on(:tax_1_rate)
  end
    
  def test_blank_rate_ok_when_name_blank
    
    login_as :user_without_profile

    # test blank rate is OK when name is blank
      put :update, :profile => {:tax_1_name => "", :tax_1_rate => '', :tax_2_name => '', :tax_2_rate => ""  }

      assert_response :success
      profile = assigns(:profile)
      assert_equal 0, profile.errors.length 
      
  end
  
  def test_error_blank_name
    login_as :user_without_profile

    # test name can't be blank when rate not blank
    put :update, :profile => {:tax_enabled => '1', :tax_1_name => "", :tax_1_rate => '', :tax_2_name => '', :tax_2_rate => "3.222"  }
    assert assigns(:profile), "@profile was not assigned in the update method"
    profile = assigns(:profile)  
    assert_response :success
    assert_equal false, profile.tax_enabled

  end
      
  def test_multiple_errors
    
    login_as :user_without_profile

    # more than one error: expect not a number error, plus negative error
      put :update, :profile => {:tax_enabled => '1', :tax_1_name => " nice tax", :tax_1_rate => ' 1.00G+1', :tax_2_name => 'neg tax', :tax_2_rate => "-3.222"  }

      assert_response :success
      profile = assigns(:profile)
      assert_equal 2, profile.errors.length
      assert_equal 'must be a number. Please enter a valid number greater than 0.', profile.errors.on(:tax_1_rate)
      assert_equal "must be a number. Please enter a valid number greater than 0.", profile.errors.on(:tax_2_rate)
  end

  def test_canada_partial
    login_as :user_without_profile
    
    put :switch_country, :profile => {:country => 'CA'  }
    assert_response :success
    assert_select 'label', /^Province/
    assert_select 'label', /^Postal Code/
    assert_select 'select#profile_company_state'
    assert_select 'option', 'Newfoundland and Labrador'
  end
  
  def test_us_partial
    login_as :user_without_profile
    
    put :switch_country, :profile => {:country => 'US'  }
    assert_response :success
    assert_select 'label', /^State/
    assert_select 'label', /^Zip Code/
    assert_select 'select#profile_company_state'
    assert_select 'option', 'Virginia'
  end
  
  def test_other_partial
    login_as :user_without_profile
    
    put :switch_country, :profile => {:country => 'BE'  }
    assert_response :success
    assert_select 'label', /^Province/
    assert_select 'label', /^Postal Code/
    assert_select 'input#profile_company_state'
  end
  
  def test_selected_country
    login_as :basic_user 
    put :switch_country, :profile => {:country => 'CA'  }
    profile = assigns(:profile)
    profile.clean_up_country_and_province
    assert_equal "CA", profile.country
  end
  
  def test_unselected_country
    login_as :basic_user 
    put :switch_country, :profile => {:country => ::AppConfig.select_country_string  }
    profile = assigns(:profile)
    profile.clean_up_country_and_province
    assert_equal "", profile.country    
  end

  # trac #480
  def test_wrong_logo_type_does_not_throw

    fdata = fixture_file_upload('/files/bob.txt', 'text/text')

    assert_nothing_raised do
      assert_no_difference 'Logo.count', 2 do
        put :update, :logo => { :uploaded_data => fdata}, :html => { :multipart => true }
      end
    end

    assert_response :success
    assert_not_nil assigns(:logo)
    deny assigns(:logo).errors.empty?

  end

  def test_mobile_view
    get :edit, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end
  
  def test_mobile_submit_correcty_renders
    get :edit, :mobile => 'true'
    login_as :basic_user 
    put :update, :profile => {:company_name => "test company" }
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("prohibited")
  end
    
  def test_mobile_error_render
    get :edit, :mobile => 'true'
    login_as :basic_user 
    put :update, :profile => {:tax_enabled => '1', :tax_1_name => " neg tax", :tax_1_rate => '-1', :tax_2_name => 'neg tax', :tax_2_rate => "-3.222"  }   
    assert @response.body.include?("mobile.css")
    assert @response.body.include?("prohibited")    
  end
  
  def test_toggle_specify_heard_from
  	login_as :basic_user
	  put :update, :profile => {:heard_from => "other"}
	  assert_response :success
	  profile = assigns(:profile)
	  assert_equal "other", profile.heard_from
  end
  
  def test_referrals_questions_should_be_hidden_when_complete
    login_as :basic_user
	  put :update, :profile => {:heard_from => "other"}
	  assert_response :success
	  profile = assigns(:profile)
	  assert @response.body.include?("div_specify_heard_from")
	  
	  put :update, :profile => {:heard_from => "Banks"}
	  assert_response :success
	  profile = assigns(:profile)
	  assert !@response.body.include?("div_specify_heard_from")
  end
  
  def test_addressing_route
	  login_as :basic_user
	  get :edit, :setting => "addressing"
	  assert @response.body.include?("Set up your business address")
  end
  
  def test_tax_route
	  login_as :basic_user
	  get :edit, :setting => "taxes"
	  assert @response.body.include?("Set up your tax settings")
  end
  
  def test_logo_route
	  login_as :basic_user
	  get :edit, :setting => "logo"
	  assert @response.body.include?("Upload a logo")
  end
  
  def test_communications_route
	  login_as :basic_user
	  get :edit, :setting => "communications"
	  assert @response.body.include?("Subscribe to Billing Boss!")
  end
  
  def test_online_payments_route
	  login_as :basic_user
	  get :edit, :setting => "payments"
	  assert @response.body.include?("Collect payments online")
  end
  
  def test_goes_to_next_tab_on_successful_save
    login_as :basic_user
    put :update, {:profile_tab => "taxes", :profile => {:tax_1_name => 'wonderful tax', :tax_1_rate => " 1.5"  }}
    assert_response :success
    assert @response.body.include?("Upload a logo") #next page
  end
  
  def test_does_not_go_to_next_tab_on_error
    login_as :basic_user
    put :update, {:profile_tab => "taxes", :profile => {:tax_1_name => 'wonderful tax', :tax_1_rate => "-5"  }}
    assert_response :success
    assert @response.body.include?("Set up your tax settings")
  end

  def test_should_set_tax_1_in_taxable_amount_setting
   login_as :user_without_profile
      put :update, :profile => {:tax_enabled => '1', :tax_1_name => " nice tax", :tax_1_in_taxable_amount=>"1"  }
      assert_response :success

      assert  @controller.current_user.profile.tax_1_in_taxable_amount

      put :update, :profile => {:tax_enabled => '1', :tax_1_name => " nice tax", :tax_1_in_taxable_amount=>"0"  }
      assert_response :success

      assert  !@controller.current_user.profile.tax_1_in_taxable_amount
  end
  
end




