$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'


#test cases for user login
class AjaxCounterTest < SageTestCase
  include AcceptanceTestSession
  fixtures :users
  

  def setup
    @session = watir_session
  end
  
  def teardown 
    @session.teardown
  end
 
  def test_ajax_counter
    @session.goto(@session.url)
    assert @session.div(:id, 'ajax_counter').exists?
  
    @session.expects_ajax(1) do
      @session.link(:text, 'test_ajax').click
    end
    
    assert_equal("Changed You", @session.div(:id, "branding").text)
   
  end
end
