$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'


# Test cases for User Story 87
# User can email bookkeeping invitation as HTML link
class SendBookkeepingInvitation < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  
  def setup
    @user = watir_session.with(:email_user)
    @user.logs_in
    start_email_server

    @tornado = @user.site_url + '/'
    @accessPath = @tornado + "access/"
  end
  
  def teardown
    end_email_server
    @user.teardown
  end
  
  def test_rejects_bad_email_address
    @user.goto(@user.site_url + '/bookkeepers')
    @user.expects_ajax do
      @user.link(:id, "show-send-dialog-btn").click
    end
    @user.populate(@user.text_field(:id, "delivery_recipients"),"bademail@x.x")
    # @debug = true
    exit unless $test_ui.agree("click send?", true) if @debug
    @user.expects_ajax do
      @user.button(:value, "Send").click
    end
    exit unless $test_ui.agree("has an error?", true) if @debug
    assert @user.div(:id,'errorExplanation').text.match(/error prohibited.*being saved/) 
    assert @user.div(:id,'errorExplanation').text.match(/must be.*email addresses/) 
        
  end
  
  
  # Create an invoice, code is based on previous tests
  # Customer has a contact that has email autotest@INNOV-TESTEMAIL.dev.peachtree.com
  # Send the invoice, then sleep
  # Read the email from the web server and check the invitation link works.
  # TODO: Should read the e-mail from the Deliveries table instead.
  def test_send_bookkeeping_invitation
    # set the contact email, maybe this will be done automatically later
    @user.goto(@user.site_url + '/bookkeepers')
    
    @user.expects_ajax do
      @user.link(:id, "show-send-dialog-btn").click
    end
    
    @user.populate(@user.text_field(:id, "delivery_recipients"),@user.autotest_email)

    # get the deliverableId from a hidden field and use later to read the deliveries table
    @deliverableId = @user.hidden(:id, "delivery_deliverable_id").value
    
    message_id = @user.wait_for_delivery_of(@deliverableId, "send invitation") do    
      @user.button(:value, "Send").click
      @user.wait
    end
    
    @user.div(:id,'new_delivery_container').text.match 'successful'
    
    # expect the popup to be gone after clicking Close
    assert @user.div(:id, 'send-dialog-container').visible?
    @user.button(:value,'Close').click
    # assert !@user.div(:id, 'send-dialog-container').visible?

#    mail = @user.read_email_from_server('autotest@10.152.17.65') do |m|
#      puts "checking #{m.message_id} == #{message_id}: #{m.message_id == message_id}"
#      m.message_id == message_id
#    end
#      
#    @accessLink = /https?:\/\/.+\/access\/.+/.match(@user.extract_text_from_mail(mail)).to_s

    @accessLink = "#{::AppConfig.host}/access/#{AccessKey.find(:all).last.key}/"
   
    assert @accessLink.length > 0
    
    # expect web page asks browser to accept/decline invitation
    
    @user.logs_out
    @user = watir_session.with(:basic_user)
    @user.logs_in
    
    @user.goto(@accessLink)
    
    assert @user.text.match(/Do you accept/)
    assert @user.button(:value,"Accept").exists?
    assert @user.button(:value,"Decline").exists?    
  end # test
  
private
  
  
end
