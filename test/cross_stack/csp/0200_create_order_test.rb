$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/csp_test_helper'
require File.dirname(__FILE__) + '/../sso'


class CreateOrderTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.proveng.ensure
    Sage::Test::Server.csp.ensure
    @user = watir_session
    SSO::Proveng.prepare(true)
    SSO::CSP.prepare(true)
    @debug = false
    @user.logs_in_as_clerk(@debug)
  end
  
  def test_create_order_with_existing_account_from_orders_page
    @user.goto Sage::Test::Server.csp.url + '/orders'
    # @debug = true
    assert @user.link(:id, 'orders-new--link').exists?, "no create new order link!"
    @user.link(:id, 'orders-new--link').click
    @user.wait_until_exists("orders-create--form")
    @user.fills_in_form_from_hash(
      {
        "record[account_name]" => "existing_user",
        "record[dorder_num]" => "test_create_order_with_existing_account_from_orders_page",
      },
      {
        :assert_keys => true,
        :by_name => true,
        :form_id => 'orders-create--form'
      }
    )
    
    @user.select_list(:name => /record\[order_lines\]\[\d+\]\[service_code\]/, :index => 1).set("I-03 - Data backup")
    # debugger
    @user.text_field(:name => /record\[order_lines\]\[\d+\]\[qty\]/, :index => 1).set("1")

    @user.submits
    exit unless $test_ui.agree("ready to fill in order?", true) if @debug
  end
  
  def test_create_order_with_new_account
    @user.link(:id, 'accounts-new--link').click        
    @user.wait_until_exists("accounts-create--form")
    user_attrs = valid_account_attributes
    @user.fills_in_form_from_hash( user_attrs,
      {
        :assert_keys => true,
        :form_id => 'accounts-create--form',
        :prefix => 'record[',
        :suffix => ']',
        :by_name => true
      }
    )
    
    # debugger

    @user.submits

    exit unless $test_ui.agree("submit?", true) if @debug
    p = Proc.new {|e| e.text == "Created #{user_attrs[:account_name]}"}
    @user.wait_until_predicate(p, "accounts-messages")
    
    #assert @user.div(:id, 'accounts-messages').exists?
    assert @user.div(:id, 'accounts-messages').text.include?("Created #{user_attrs[:account_name]}")
  end
  
  def test_show_order_preview
  end
end