$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
#require File.dirname(__FILE__) + '/../../app/helpers/profiles_helper'

# Test cases for User Story XXX
class TaxPreferencesTest < SageAccepTestCase
  include AcceptanceTestSession
  include ProfilesHelper
  fixtures :users
  
  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
  end
  
  def teardown
   @user.teardown
  end

  def test_enable_taxes_checkbox
    
    # check the tax enabled checkbox, save, and ensure it's checked
    @user.goto(@user.site_url + '/profiles/')
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set
    @user.wait
    @user.button(:name, "commit").click
    @user.wait
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    assert !@user.checkbox(:name, 'profile[tax_enabled]').checked?
    
    # blank taxes = taxes disabled
    @user.goto(@user.site_url + '/profiles/')
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set
    @user.wait
    @user.button(:name, "commit").click
    @user.b.wait
    @user.wait
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    assert !@user.checkbox(:name, 'profile[tax_enabled]').checked?

    @user.goto(@user.site_url + '/profiles/')
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set

    @user.text_field(:id, 'profile_tax_1_name').set('tax 1')
    @user.text_field(:id, 'profile_tax_1_rate').set('5')
    @user.wait
    @user.button(:name, "commit").click
    @user.wait
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    assert @user.checkbox(:name, 'profile[tax_enabled]').checked?
  end
  
  def test_enable_taxes_cleared
    # Test when the checkbox is checked that tax controls are NOT available.
    @user.goto(@user.site_url + '/profiles/')
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').clear
        @user.b.wait
    assert !@user.text_field(:name,'profile[tax_1_name]').visible?
    # use the ID to find the checkbox instead of the hidden field with the same name
    assert !@user.checkbox(:id,'profile_discount_before_tax').visible?
  end
  
  def test_enable_taxes_checked
    # Test when the checkbox is checked that tax controls are available.
    @user.goto(@user.site_url + '/profiles/')
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set
    @user.b.wait
    assert @user.text_field(:name,'profile[tax_1_name]').visible?
    # use the ID to find the checkbox instead of the hidden field with the same name
    assert @user.checkbox(:id,'profile_discount_before_tax').visible?
  end
  
  def test_enable_taxes_checked_canada
    # Test when the checkbox is checked and the country is Canada,
    # that the official values are accessible. 
    @user.goto(@user.site_url + '/profiles/')
    @user.expects_ajax(1) do
      @user.select_list(:name,'profile[company_country]').select("Canada")
    end
    @user.select_list(:name,'profile[company_state]').select("Ontario")
	@user.text_field(:name, 'profile[company_postalcode]').set('V1V 1V1')
    @user.button(:name, "commit").click
    @user.wait
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set
    assert @user.contains_text('official tax values')
  end
  
  def test_enable_taxes_checked_not_canada
    # Test when the checkbox is checked and the country is Canada,
    # that the official values are NOT accessible. 
    @user.goto(@user.site_url + '/profiles/')
    @user.expects_ajax(1) do
      @user.select_list(:name,'profile[company_country]').select("France")
    end
    @user.button(:name, "commit").click
    @user.wait
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set
    #assert not @user.contains_text('Click here to use the official tax values for your province')
  end
  
  def test_invalid_data_not_saved
    # We're doing this test here because we could not get it to work in the controller test... 
    # It would work with use_transactional_fixtures = false, but not when true.
    
    # Store the valid values in tax_2, then attempt to save invalid values, 
    # and expect the values in the database to be unchanged
    
    # set a valid tax_2_rate, expecting no error
      @user.goto(@user.site_url + '/profiles/')
      @user.link(:id, 'user_taxes_link').click
      @user.b.wait
      @user.checkbox(:name, 'profile[tax_enabled]').set
      @user.text_field(:name, 'profile[tax_2_name]').set( 'valid' )
      @user.text_field(:name, 'profile[tax_2_rate]').set( '1000' )
      @user.button(:name, 'commit').click
      @user.wait
      assert !@user.contains_text('There were problems with the following fields')
    

    # refresh the page, expecting the valid values
      @user.goto(@user.site_url + '/profiles/')
      @user.link(:id, 'user_taxes_link').click
      @user.b.wait
      assert_equal 'valid', @user.text_field(:name, 'profile[tax_2_name]').value
      assert_equal BigDecimal.new('1000'), BigDecimal.new(@user.text_field(:name, 'profile[tax_2_rate]').value)
      
  end
  
  def test_defaults_set_for_ontario
    @user.goto( @user.site_url + '/profiles/' )
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.checkbox(:name, 'profile[tax_enabled]').set
    @user.text_field(:name, 'profile[tax_1_name]').set('')
    @user.text_field(:name, 'profile[tax_1_rate]').set('')
    @user.text_field(:name, 'profile[tax_2_name]').set('')
    @user.text_field(:name, 'profile[tax_2_rate]').set('')
    @user.link(:id, 'user_addressing_link').click
    @user.b.wait
    @user.expects_ajax(1) do
      @user.select_list(:name,'profile[company_country]').select("Canada")

    end
    @user.select_list(:name,'profile[company_state]').select("Ontario")
	@user.text_field(:name, 'profile[company_postalcode]').set('V1V 1V1')
	@user.button(:name, "commit").click
    @user.wait
    @user.link(:id, 'user_taxes_link').click
    @user.b.wait
    @user.link(:id,'taxes_official_link').click

    if true
      assert_equal 'GST', 
        @user.text_field(:name, 'profile[tax_1_name]').value
      assert_equal '5.0', 
        @user.text_field(:name, 'profile[tax_1_rate]').value
      assert_equal 'PST', 
        @user.text_field(:name, 'profile[tax_2_name]').value
      assert_equal '8.0', 
        @user.text_field(:name, 'profile[tax_2_rate]').value
    else
      #TODO: Store tax values in only one helper file... figure out how to include this helper in the form ERB.
      assert_equal ProfilesHelper::TAXES_FOR_PROVINCES['ONTARIO']['tax_1_name'], 
        @user.text_field(:name, 'profile[tax_1_name]').value
      assert_equal ProfilesHelper::TAXES_FOR_PROVINCES['ONTARIO']['tax_1_rate'], 
        @user.text_field(:name, 'profile[tax_1_rate]').value
      assert_equal ProfilesHelper::TAXES_FOR_PROVINCES['ONTARIO']['tax_2_name'], 
        @user.text_field(:name, 'profile[tax_2_name]').value
      assert_equal ProfilesHelper::TAXES_FOR_PROVINCES['ONTARIO']['tax_2_rate'], 
        @user.text_field(:name, 'profile[tax_2_rate]').value
    end
    
  end

#seems like below method is obsolete because you can't select "no province" anymore  
#  def test_defaults_not_set_for_unknown_province
#    @user.goto( @user.site_url + '/profiles/' )
#
#    @user.checkbox(:name, 'profile[tax_enabled]').set    
#    @user.text_field(:name, 'profile[tax_1_name]').set('')
#    @user.text_field(:name, 'profile[tax_1_rate]').set('')
#    @user.text_field(:name, 'profile[tax_2_name]').set('')
#    @user.text_field(:name, 'profile[tax_2_rate]').set('')
#    
#
#    
#    @user.expects_ajax(1) do
#      @user.select_list(:name,'profile[company_country]').select("Canada")
#    end
#
#    @user.select_list(:name,'profile[company_state]').select("")
#    @user.link(:id,'taxes_official_link').click
#    
#    assert_equal '', @user.text_field(:name, 'profile[tax_1_name]').value
#    assert_equal '', @user.text_field(:name, 'profile[tax_1_rate]').value
#    assert_equal '', @user.text_field(:name, 'profile[tax_2_name]').value
#    assert_equal '', @user.text_field(:name, 'profile[tax_2_rate]').value
#  end
  
end

