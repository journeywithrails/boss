require File.dirname(__FILE__) + '/../test_helper'

class ApiAppVersionTest < ActiveSupport::TestCase
  
  def test_create_empty_app_version
    av = ApiAppVersion.new(nil)
    assert_not_nil av
    assert_nil av.appname
    assert_nil av.country
    assert_nil av.number
    assert_nil av.release_date
    assert_equal '', av.to_s
  end

  def test_create_partial_app_version
    av = ApiAppVersion.new('MyApp-US')
    assert_not_nil av
    assert_equal 'MyApp', av.appname
    assert_equal 'US', av.country
    assert_nil av.number
    assert_nil av.release_date
    assert_equal 'MyApp-US', av.to_s
  end
  
  def test_create_full_app_version
    av = ApiAppVersion.new('DifferentApp-CA-2.0.10-20080101')
    assert_not_nil av
    assert_equal 'DifferentApp', av.appname
    assert_equal 'CA', av.country
    assert_equal '2.0.10', av.number
    assert_equal '20080101', av.release_date
    assert_equal 'DifferentApp-CA-2.0.10-20080101', av.to_s
  end
    
end
