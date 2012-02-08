$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

require 'hpricot'

class SimplyIntegrationTest < SageAccepTestCase
  include SimplyApiTestHelpers
  include AcceptanceTestSession

  fixtures :users
  def setup
    @user = watir_session.with(:user_without_profile)
  end
  
  def teardown
    @user.teardown
  end
  
  def test_happy_path_signing_up_and_sending_invoice
    
    # create send-invoice-browsal 
      #curl_command = 'curl.exe -H "Content-Type: application/xml; charset=utf-8" --data-ascii @c:\devt\simply\doc\example_simply_send_invoice.xml "http://localhost:3000/browsals" '
      curl_command = %|curl -H "Content-Type: application/xml; charset=utf-8" --data-ascii @doc\\example_simply_send_invoice.xml "#{@user.site_url}/browsals" |
      response = `#{curl_command}`
      

      
    # get URL for signing up from the browsal, and go
      response_xml = response.gsub(/[[:cntrl:]]/,"").scan(/<\?xml.*<\/send-invoice-browsal>/)[0]
      xml = Hpricot.XML(response_xml)
      root = (xml/"send-invoice-browsal")
      assert_match /users\/new$/, (root/"current-url").inner_html
      next_url = current_url_from_xml(root)
      @user.goto @user.site_url + next_url
      
    # signup 
      @user.text_field(:id,"user_login").set("test@test.com")
      @user.text_field(:id,"user_password").set("test" )
      @user.text_field(:id,"user_password_confirmation").set("test")
      @user.checkbox(:id, "user_terms_of_service").set("1")
      @user.button(:id, "register_button").click
    
    # choose to send the invoice now
      assert @user.contains_text("Thanks for signing up!"), "web page should say 'Thanks for signing up!'"
      assert_match 'Send the invoice now', @user.div(:class,'caption').text,"page should include this caption"
      assert_match 'Send the invoice later', @user.div(:class,'caption').text,"page should include this caption"
      @user.link(:id,"email-the-invoice-button").click
      
    # view invoice summary and send now
      assert @user.contains_text("invoice summary is displayed on this page"), "page should say 'invoice summary is displayed on this page'"
      assert_equal "987654321", @user.span(:id,"invoice_unique").text, "Expecting the invoice summary to show invoice number 987654321"
      assert @user.contains_text("Do you want to send the invoice"), "page should ask 'Do you want to send the invoice'"
      @user.link(:id,"send-invoice-yes").click
      
    # click on "Send Complete" button to close the browser
      @user.button(:id,"complete-btn").click
      
      
    # failed attempt at using Net:HTTP to create a browsal
    #    res = Net::HTTP.post_form(URI.parse('http://localhost:3000/browsals'),
    #                                {:simply_request => {:browsal => {:browsal_type => 'SendInvoiceBrowsal' }, 
    #       :invoice => simply_invoice_attributes,
    #                              :delivery => simply_delivery_attributes }} )
    #
    # failed attempt at using ActiveResource to create a browsal
    #    
    #  class Browsal < ActiveResource::Base 
    #    self.site = "http://localhost:3000/"
    #  end
    #
    #    foo = Browsal.new( :simply_request => {
    #      :browsal => {:browsal_type => 'SendInvoiceBrowsal' }, :invoice => simply_invoice_attributes,
    #      :delivery => simply_delivery_attributes }, :format => 'xml' )
    #    foo = Browsal.new( :simply_request => {
    #      :browsal => {:browsal_type => 'SendInvoiceBrowsal' }}, :format => 'xml' )
    #    puts foo.save
    #    puts foo.inspect
    #
  end

  def current_url_from_xml(root)
    (root/"current-url").inner_html.sub(/http:\/\/[^\/]+/, "")
  end
  
  def browsal_from_xml(root)
    guid = (root/"guid").inner_html
    id = (root/"id").inner_html
    Browsal.find_by_browsal_guid_and_id(guid, id)
  end
  
  def path_from_session_redirect(body)
    html = Hpricot(body)
    html.search('//meta').first.attributes['content'].split('url=').last.sub(/http:\/\/[^\/]+/, "")
  end

end
