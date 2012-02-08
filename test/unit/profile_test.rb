require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../billing_helper'

class ProfileTest < Test::Unit::TestCase

  fixtures :users

  def setup
    ActiveMerchant::Billing::PaypalExpressGateway.any_instance.stubs(:ssl_post).returns(unsuccessful_setup_purchase_response)
    UserMailer.stubs(:deliver_signup_notification)
  end
  
  def test_time_zone_returned
     u = User.new
     p = u.profile

     assert_equal "GMT", p.tz
     u.profile.time_zone = "America/Central"
     assert_equal "America/Central", p.tz
   end
   
  def test_switch_accessors
    
    u = User.new
    p = u.profile
    assert p.tax_enabled, 'taxes should be enabled, by default, for new users'
    assert p.discount_before_tax, 'discounts should be applied before taxes, by default, for new users'
    
    u = users(:basic_user)
    assert !u.profile.tax_enabled
    assert u.profile.discount_before_tax
    
    u = users(:complete_user)
    assert u.profile.tax_enabled
    
  end

  def test_transparently_creates_tax_1_object
    user = users(:basic_user)
    assert user.taxes.empty?, "to start off user has no tax objects"
    user.profile.tax_1_rate = "4.8"
    user.profile.tax_1_name = "bob"
    deny user.taxes.empty?, "after setting tax_1_rate, user.taxes should not be empty"
    user.save!
    user.reload
    assert_not_nil user.taxes.find_by_profile_key('tax_1'), "after setting tax_1_rate, user.taxes should have a tax with profile_key == tax_1"
    assert_equal BigDecimal("4.8"), user.taxes.find_by_profile_key('tax_1').rate, "after setting tax_1_rate, user.taxes should have a tax with rate == to that rate"
    assert_equal "bob", user.taxes.find_by_profile_key('tax_1').name, "after setting tax_1_rate, user.taxes should have a tax with rate == to that rate"
  end
  
  def test_transparently_creates_tax_2_object
    user = users(:basic_user)
    assert user.taxes.empty?, "to start off user has no tax objects"
    user.profile.tax_2_rate = "6.7"
    user.profile.tax_2_name = "mary"
    deny user.taxes.empty?, "after setting tax_2_rate, user.taxes should not be empty"
    user.save!
    assert_not_nil user.taxes.find_by_profile_key('tax_2'), "after setting tax_2_rate, user.taxes should have a tax with profile_key == tax_2"
    assert_equal BigDecimal("6.7"), user.taxes.find_by_profile_key('tax_2').rate, "after setting tax_2_rate, user.taxes should have a tax with rate == to that rate"
    assert_equal "mary", user.taxes.find_by_profile_key('tax_2').name, "after setting tax_2_rate, user.taxes should have a tax with rate == to that rate"
  end
  

  def test_complete_profile
    u = users(:user_without_profile)
    p = u.profile
    assert p.valid?
    deny p.is_complete?
    
    p.heard_from = "Banks"
    p.company_name = "Name 1"
    p.company_address1 = "Address 1"
    p.company_city = "City 1"
    p.company_country = "Country 1"
    p.company_phone = "123 456 7890"
    
    assert p.is_complete?
       
    p.company_name = ""
    deny p.is_complete?
    
    p.contact_name = "Name 2"
    assert p.is_complete?
    
    p.company_city = ""
    deny p.is_complete?
    
    p.company_city = "City 1"
    p.company_country = ""
    deny p.is_complete?
    
    p.company_country = "US"
    deny p.is_complete?
    
    p.company_state = "Ohio"
    p.company_postalcode = "12345"
    assert p.is_complete?
    
    p.company_state = ""
    deny p.is_complete?
    
    p.company_state = "Ohio"
    p.company_postalcode = ""
    deny p.is_complete?
    
    p.heard_from = ""
    deny p.is_complete?
    
    p.heard_from = "other"
    deny p.is_complete?
  end
  

  # def test_validation    
  #   u = users(:basic_user)
  #   p = u.profile
  #   p.tax_1_rate = '-2'
  #   p.tax_2_name = ''
  #   assert !p.valid?
  #   assert_equal 2, p.errors.length 
  #   assert_equal "cannot be negative", p.errors.on(:tax_1_rate)
  #   assert_equal 'cannot be blank if the rate is defined', p.errors.on(:tax_2_name)
  #   
  # end
  # 

  def test_for_code_coverage
    
    u = users(:basic_user)
    p = u.profile
    assert_equal 'BI', p.country
    
    # discount_before_tax
      assert p.discount_before_tax
      p.discount_before_tax = false      

      p.reload

      assert p.discount_before_tax

      p.discount_before_tax = false      
      p.save!
      p.reload      
      assert !p.discount_before_tax

      p.discount_before_tax = true
      p.save!; p.reload
      assert p.discount_before_tax
    
    # tax_enabled
      assert !p.tax_enabled
      p.tax_enabled = true
      p.save!; p.reload
      assert p.tax_enabled
      p.tax_enabled = false
      p.save!; p.reload
      assert !p.tax_enabled

      p.logo
      p.web_invoice_css
  end

  def test_should_dirty_user_pdf_cache
    u = users(:basic_user)
    p = u.profile
    
    p.user_record.expects(:pdf_dirty_cache)
    p.dirty_cache
  end

  def test_should_return_payment_gateway
end

  def test_new_user_current_view
    u = create_user()
    u.save
    
    assert_same :biller, u.profile.current_view, "New User should have a biller current view"
  end
  
  def test_set_user_current_view
    u = create_user()
    u.save
    u.profile.current_view = :bookkeeper
    u.profile.save!; u.profile.reload
    assert_equal :bookkeeper, u.profile.current_view, "User should have set bookkeeper current view"
  end

#  def test_validates_paypal_account_with_bad_credentials
#    return if $paypal_hidden  
#    u = users(:user_without_profile)
#    p = u.profile
#    p.paypal_account_type = Profile.paypal_account_types["Paypal Express"]
#    p.paypal_password = 'test'
#    p.paypal_API_key = 'test'
#    p.paypal_user_id = 'test'
#    p.paypal_email_address = 'something@somewhere.com'
#    ActiveMerchant::Billing::PaypalExpressGateway.any_instance.expects(:ssl_post).returns(unsuccessful_setup_purchase_response)
#    assert ! p.valid?, "with paypal_account_type = 'Paypal Express' and bogus credentials, profile should be invalid"
#  end

  def test_validates_paypal_account_with_good_credentials
    return if $paypal_hidden  
    u = users(:user_without_profile)
    p = u.profile
#    p.paypal_account_type = Profile.paypal_account_types["Paypal Express"]
#    p.paypal_user_id = paypal_test_api_username
#    p.paypal_password = paypal_test_api_password
#    p.paypal_API_key = paypal_test_api_key
    p.paypal_email_address = 'something@somewhere.com'
#    ActiveMerchant::Billing::PaypalExpressGateway.any_instance.expects(:ssl_post).returns(successful_setup_purchase_response)
    p.valid?
    assert_equal [], p.errors.full_messages
  end

#  def test_validate_paypal_not_setup_fails
#    return if $paypal_hidden  
#    u = users(:user_without_profile)
#    p = u.profile
#    p.paypal_account_type = Profile.paypal_account_types["Paypal Express"]
#    assert !p.valid?, "with paypal_account_type = 'Paypal Express' and no credentials, profile should be invalid"
#  end

  def test_validate_new_profile
    u = users(:user_without_profile)
    p = u.profile
    assert p.valid?, "new blank profile starts off valid"
  end

  def test_empty_country_string
    u = users(:basic_user)
    p = u.profile
    p.country = ::AppConfig.select_country_string.to_s
    p.clean_up_country_and_province
    assert_equal '', p.country
  end

unless %w{production staging load_testing}.include? ENV['RAILS_ENV']
  def test_accept_default_theme
    u = create_user()
    u.save
    p = u.profile
    assert_equal "Default", p.theme
  end
  
  def test_accept_valid_theme
    u = create_user()
    u.save    
    p = u.profile
    p.theme = "Test"
    p.save!
    # include 1 test that goes through user again to get profile
    u2 = User.find(u.id)
    p2 = u2.profile
    assert_equal "Test", p.theme
  end
  def test_reject_invalid_theme
    u = create_user()
    u.save    
    p = u.profile
    p.theme = "asdf"
    p.save!; p.reload
    assert_equal "Default", p.theme

    p.theme = ""
    p.save!; p.reload
    assert_equal "Default", p.theme
    
    p.theme = "default" #capitalization matters
    p.save!; p.reload
    assert_equal "Default", p.theme
    
  end
  
  def test_opt_in
    u = create_user()
    u.save!    
    p = u.profile
    assert_equal false, p.mail_opt_in
    p.mail_opt_in = false
    p.save!
    u.save!
    p = u.profile
    assert_equal false, p.mail_opt_in
  end
  
  def test_invalid_currency
    u = create_user()
    u.save!    
    p = u.profile
    p.currency = nil
    assert_equal "USD", p.currency
    p.currency = "asdf"
    assert_equal "USD", p.currency
  end
  
  def test_default_payment_types
    u = create_user()
    u.save!    
    p = u.profile
    assert_equal p.online_payment_types_list, p.online_payment_types
  end
  
  def create_user(options = {})
    User.create({ :sage_username => 'quire',
      :email => 'quire@example.com',
      :password => 'quire', 
      :password_confirmation => 'quire', 
      :terms_of_service => '1' }.merge(options))
  end  

  def test_save_without_validation_works
    Profile.any_instance.stubs(:valid?).returns(false)

    u = create_user()

    u.save    
    p = u.profile

    p.company_name = "The Company Name Should Save"
    deny p.save
    p.reload
    assert_not_equal "The Company Name Should Save", p.company_name

    p.company_name = "The Company Name Should Save"
    assert p.save(false)
    p.reload
    assert_equal "The Company Name Should Save", p.company_name
  end
end

end


