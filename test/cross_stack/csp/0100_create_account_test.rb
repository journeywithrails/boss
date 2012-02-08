$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/csp_test_helper'
require File.dirname(__FILE__) + '/../sso'


class CreateAccountTest < Test::Unit::TestCase
  include AcceptanceTestSession

  def setup
    # $log_on = true
    Sage::Test::Server.proveng.ensure
    Sage::Test::Server.csp.ensure
    @user = watir_session
    SSO::Proveng.prepare(true)
    SSO::CSP.prepare(true)
    @debug = false    
  end

  def teardown
    @user.logs_out
  end
  
  def test_create_account_validation
    @user.logs_in_as_clerk(@debug)    
    assert @user.link(:id, 'accounts-new--link').exists?

    @user.link(:id, 'accounts-new--link').click
        
    exit unless $test_ui.agree("on create account?", true) if @debug
    @user.wait_until_exists("accounts-create--form")

    @user.submits
    assert @user.div(:id, 'accounts-create--messages').exists?
  end
  
  def test_create_account
    @user.logs_in_as_clerk(@debug)    
    assert @user.link(:id, 'accounts-new--link').exists?

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
    
    @user.submits
    
    p = Proc.new {|e| e.text == "Created #{user_attrs[:account_name]}"}
    @user.wait_until_predicate(p, "accounts-messages")
    #debugger
    assert @user.div(:id, 'accounts-messages').text.include?("Created #{user_attrs[:account_name]}")
  end
  
  def test_create_account_thru_sam_and_sbb
    sage_user = new_account
    puts "creating account for #{sage_user.username}"
    @user.logs_out_cas
    @user.logs_in_as_clerk(@debug)
    @user.link(:id, 'create-sage-spark-account').click
    @user.wait_until_exists('register_button')
    exit unless $test_ui.agree("on sam?", true) if @debug
    @user.text_field(:id,"sage_user_username").set(sage_user.username)
    @user.text_field(:id,"sage_user_email").set(sage_user.email)
    @user.text_field(:id,"sage_user_first_name").set(sage_user.first_name)
    @user.text_field(:id,"sage_user_last_name").set(sage_user.last_name)
    exit unless $test_ui.agree("submit?", true) if @debug
    @user.button(:id, "register_button").click
    @debug = true
    exit unless $test_ui.agree("on sbb?", true) if @debug
    assert @user.contains_text("Welcome,"), "page should have 'Welcome #{sage_user.username}' message"
    # @user.link(:text, /Business Information/).click
    # exit unless $test_ui.agree("industry_drop_down?", true) if @debug
    @user.wait_until_exists('industry_drop_down')
    @user.text_field(:id,"edit-title").set('Company ' + sage_user.username.titleize)
    @user.text_field(:id,"edit-locations-0-street").set('123 Street')
    @user.text_field(:id,"edit-locations-0-city").set('Vancouver')
    @user.select_list(:id,"edit-locations-0-country").select_value('ca')
    @user.select_list(:id,"edit-locations-0-province").select_value('ca-BC')
    @user.text_field(:id,"edit-field-business-phone-0-value").set('778-840-7207')
    @user.text_field(:id,"edit-locations-0-postal-code").set('V7V 7V7')

    @user.select_list(:id, "industry_drop_down").select_value("160")
    @user.select_list(:id, "bus_cat_drop_down").select_value("175")
    @user.button(:value, "Submit").click    
    exit unless $test_ui.agree("on csp?", true) if @debug
  end
  
  def new_account
    OpenStruct.new ({
      :username => "csp#{Time.now.to_i.to_s}",
      :email => "csp#{Time.now.to_i.to_s}@billingboss.com",
      :first_name => 'Csp',
      :last_name => 'Dude'      
    })
  end
end