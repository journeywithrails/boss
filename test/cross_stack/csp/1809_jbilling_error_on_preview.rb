$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/csp_test_helper'
require File.dirname(__FILE__) + '/../sso'


class JbillingOrderOnPreviewTest < Test::Unit::TestCase
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
  
  def test_preview_order_shows_jbilling_error
    @user.goto Sage::Test::Server.csp.url + '/orders'
    assert @user.link(:id, 'orders-new--link').exists?, "no create new order link!"
    @user.link(:id, 'orders-new--link').click
    @user.wait_until_exists("orders-create--form")
    @user.fills_in_form_from_hash(
      {
        "record[account_name]" => "existing_user",
      },
      {
        :assert_keys => true,
        :by_name => true,
        :form_id => 'orders-create--form'
      }
    )
    
    @user.select_list(:name => /record\[order_lines\]\[\d+\]\[service_code\]/, :index => 1).set("I-03 - Data backup")
    @user.text_field(:name => /record\[order_lines\]\[\d+\]\[qty\]/, :index => 1).set("1")
    
    @debug = true
    exit unless $test_ui.agree("ready to fill in order?", true) if @debug
    deny @user.p(:class, /jbilling-error/).exists?
    @user.submits
    @user.wait_until_exists{@user.p(:class, /jbilling-error/).exists?}
    exit unless $test_ui.agree("ready to fill in order?", true) if @debug
    assert_match /not a valid credit card number/, @user.p(:class, /jbilling-error/).text
  end
end