unless %w{production staging load_testing}.include? ENV['RAILS_ENV']
  require File.dirname(__FILE__) + '/../test_helper'

  class UserTest < Test::Unit::TestCase
    def test_loads_theme
      theme = Theme.load_theme("Test")
      assert_equal "This is the test theme", theme.description
    end
  
    def test_nil_on_invalid_theme_name
      assert_equal nil, Theme.load_theme("asdf")
    end
  
    def test_theme_validity
      assert_equal true, Theme.valid?("Test")
      assert_equal false, Theme.valid?("asdf")
      assert_equal false, Theme.valid?(" ")
      assert_equal false, Theme.valid?("")
      assert_equal false, Theme.valid?(nil)
    end
  
    def test_theme_list
      list = Theme.theme_list
      assert_equal true, list.include?("Test")
      assert_equal false, list.include?("test")
      assert_equal false, list.include?("asdf")
      assert_equal false, list.include?("")   
    end
  
  end

end