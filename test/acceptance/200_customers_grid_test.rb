
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'

# Test cases for Ticket 200 - Customers Overview Grid

class CustomersOverviewTest < Test::Unit::TestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
  end
  
  def teardown
   @user.teardown
  end
  
  def test_click_to_edit_customer
    @user.displays_customer_overview
    @user.expects_ajax(1,0)
    
    # click on the first customer link
    l = @user.link(:id, 'customers_grid-1-action-link')
    assert l.exists?
    l.click
    
    assert @user.div(:text,  "Edit Customer" ).exists?, "Expecting a customer to be edited."
  end

  def test_data_present
    # check that the customer data is present 
    
    @user.displays_customer_overview
    @user.expects_ajax(1,0)
    
    assert_equal "Customers (3)", @user.div(:id, 'customers_grid').span(:class, 'x-panel-header-text').text
    
    add_customers(12)
    
    @user.refresh

    @user.expects_ajax(1,0)

    assert_equal "Customers (15)", @user.div(:id, 'customers_grid').span(:class, 'x-panel-header-text').text
    
    # click on the next-page link, and expect just one row in the drafts grid.
      @user.expects_ajax(1) do
        @user.div(:id, 'customers_grid').button(:class, 'x-btn-text x-tbar-page-next').click
      end
      
      # find the grid div and count each customer row
        rows_found = 0 
        grid_div = @user.div(:id, 'customers_grid')
        
        grid_div.divs.each do |div|
          if div.class_name.strip == 'x-grid3-row'
            rows_found = rows_found + 1
          end
        end

      assert_equal 5, rows_found, "Expect 5 customers on the second page of the customers grid."
    
  end
  
end

def add_customers(num)
  1.upto(num) do |ix|
    users(:basic_user).customers.create(:name => "Dummy Customer #{ix}")
  end
end


