require File.dirname(__FILE__) + '/../test_helper'

class CountrySettingsTest < Test::Unit::TestCase

  fixtures :users
  
  def test_country_settings
    
    u = users(:basic_user)
    p = Profile.new( u )
    
    p.company_country = 'Canada'
    
    assert_equal 'known_country', p.country_settings.partial
    assert p.country_settings.state_label =~ /^Province/
    assert p.country_settings.postalcode_label =~ /^Postal Code/
    assert_equal 'CANADA', p.country_settings.state_key
    
    p.company_country = 'United States'
    assert_equal 'known_country', p.country_settings.partial
    assert p.country_settings.state_label =~ /^State/
    assert p.country_settings.postalcode_label =~ /^Zip Code/
    assert_equal 'US', p.country_settings.state_key
    
    p.company_country = 'Belize'
    assert_equal 'unknown_country', p.country_settings.partial
    assert p.country_settings.state_label =~ /^Province/
    assert p.country_settings.postalcode_label =~ /^Postal Code/
    assert_equal 'CANADA', p.country_settings.state_key
    
  end
  
  
end


