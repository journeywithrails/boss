require File.dirname(__FILE__) + '/../../test_helper'

class LocalizationHelperTest < HelperTestCase

  include LocalizationHelper

  #fixtures :users, :articles

  def setup
    super
  end
  
  def test_available_languages
    assert available_languages.include?("en")
    assert available_languages.include?("es")
    assert available_languages.include?("fr")
    assert available_languages.include?("zh_HK")
    assert !available_languages.include?("xx")
  end


  def test_default_language
    assert_equal "en", default_language
  end
  
  def test_default_language
    assert_equal "en_US", default_locale
  end
  
  def test_native_language_names
    # Gets list of languages, each in their native language
    assert_equal "English", select_languages_native.find{|x,y| y == "en"}[0]
    assert_equal "Français", select_languages_native.find{|x,y| y == "fr"}[0]
  end

  def test_localized_language_names
    # Gets list of languages, all in the same localized language (English)
    assert_equal "English", select_languages_localized.find{|x,y| y == "en"}[0]
    assert_equal "French", select_languages_localized.find{|x,y| y == "fr"}[0]
  end
  
  def test_language_localizer
    assert_equal "English", localize_language("en")
    assert_equal "Unknown language", localize_language("xx")
  end

  def test_languages_available
    assert 1 <= available_languages.length
  end
  
  def test_that_all_available_languages_are_in_select_lists
    assert_equal select_languages_localized.length, select_languages_native.length
    assert_equal available_languages.length, select_languages_localized.length
    assert_equal available_languages.length, select_languages_native.length
  end

end
