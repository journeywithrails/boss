require "#{File.dirname(__FILE__)}/../test_helper"
class CurrencyIntegrationTest < ActionController::IntegrationTest
  
  # The default currency for a new invoice is determined by the most recent change
  # to the profile country or to an invoice's currency.

  fixtures :users
  
  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  def test_default_currency_matches_country_just_chosen
    stub_cas_logged_in users(:basic_user)
    
    country = 'BE'
    currency = 'EUR'
    post_via_redirect 'profiles/update', :profile => {:company_country => country}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
    country = 'GB'
    currency = 'GBP'
    post_via_redirect 'profiles/update', :profile => {:company_country => country, :company_state => "Alabama", :company_postalcode => "12345"}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
    country = 'US'
    currency = 'USD'
    post_via_redirect 'profiles/update', :profile => {:company_country => country}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"

    country = 'CA'
    currency = 'CAD'
    post_via_redirect 'profiles/update', :profile => {:company_country => country, :company_postalcode => "V6V 0A3"}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
    country = 'ES'
    currency = 'EUR'
    post_via_redirect 'profiles/update', :profile => {:company_country => country}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
    country = 'UA'
    currency = 'UAH'
    post_via_redirect 'profiles/update', :profile => {:company_country => country}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
    country = 'DD' # Country no longer exists, so it doesn't have a currency
    currency = 'USD' # default currency for any unknown or undefined country
    post_via_redirect 'profiles/update', :profile => {:company_country => country}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
    country = 'No Such Country'
    currency = 'USD'
    post_via_redirect 'profiles/update', :profile => {:company_country => country}
    assert_response :success
    assert @response.body.include?("settings were successfully updated")
    users(:basic_user).profile.reload
    assert_equal currency, users(:basic_user).profile.currency, "User's currency should be #{currency} after setting the profile country to #{country}"
    
  end      
  
  def test_currency_mapping_countries_are_subset_of_all_profile_countries
    # loop through some currency-mapping countries and check they are each 
    # in the <select> dropdown for the Profile settings screen
    stub_cas_logged_in users(:basic_user)
    get 'profiles'
    assert_select "option[value='CA']"
    assert_select "option[value='GB']"
    assert_select 'select#profile_company_country' do
    end
      ['AT', 'BE', 'CY', 'FI', 'FR', 'DE', 'GR', 'IE', 'IT', 'LU', 'MT', 'NL', 'PT', 'SK', 'SI', 'ES'].each do |c|
        assert_select "option[value='#{c}']"    
      end
  end
    
  def test_default_currency_for_new_user_without_country
    # A new invoice should have USD as the selected currency 
    # if the user is new and hasn't chosen their country. 
    # The default currency is defined in currency.rb
    new_user = users(:user_without_profile)
    assert_not_nil new_user
    
    stub_cas_logged_in new_user
    
    get 'invoices/new/invoice'
    assert_select 'select#invoice_currency'
    assert_select 'option[selected=selected][value=USD]'
  end    

  def test_new_invoice_currency_matches_last_chosen_invoice_currency
    # TODO: how is the invoice currency being stored now?  Why does this test pass?
    # when an invoice is created or updated, the currency used should be the
    # default for the next invoice.
    chosen_currency = "EUR"
    stub_cas_logged_in users(:basic_user)
    assert_difference 'Invoice.count' do       
      post_via_redirect 'invoices/create', :invoice => {
        :description => 'test_create_invoice_and_on_the_fly_customer invoice',
        :customer_attributes => {:name => 'on-the-fly customer'},
        :currency => chosen_currency
      }
    end
    assert_equal chosen_currency, User.find_by_sage_username('basic_user').profile.currency, "Expect that the profile currency became the same as the last invoice update: #{chosen_currency}."  
    get 'invoices/new/invoice'
    assert_response :success
    assert_select 'select#invoice_currency'
    # Expect that the second new invoice starts with the same currency #{chosen_currency} as the first invoice that was saved.
    assert_select "option[selected=selected][value=#{chosen_currency}]"
      
  end
  
  def test_new_invoice_for_new_user_defaults_to_specified_currency
    arbitrary_default_currency = "GBP"
    Currency.stubs(:default_currency).returns(arbitrary_default_currency)
    new_user = users(:user_without_profile)
    assert_not_nil new_user
    
    stub_cas_logged_in new_user
    
    assert_equal 'GBP', new_user.profile.currency, "Expect that new user's new invoice gets the given default currency: GBP."  
    get 'invoices/new/invoice'
    assert_select 'select#invoice_currency'
    assert_select "option[selected=selected][value=#{arbitrary_default_currency}]"
  end

    
end
