require 'test/unit'
require 'fileutils'
require 'ftools'

require File.dirname(__FILE__) + '/acceptance_test_helper'

#override TestCase so that we can put in our own error handler when tests fail
class SageAccepTestCase < Test::Unit::TestCase
  
  def initialize(test_method_name)
    super(test_method_name)
  end
  
  def default_test    
  end

  def add_failure(message, all_locations=caller())    
    super(message, all_locations)
  end
  
  def add_error(exception)
    super(exception)
  end
end