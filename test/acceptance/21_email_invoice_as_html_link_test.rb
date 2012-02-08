$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__


require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 21
# User can email Invoice as HTML link
class EmailInvoiceAsHTMLLink < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers, :contacts
  
  def setup
    @user = watir_session.with(:email_user)
    start_email_server
    @user.logs_in
    @number_of_line_items = 1.00
    # define paths that are sent in email
    # use the path to get an invoice link and a paypal link that include an invoice access key
    @tornado = @user.site_url + '/'
    @accessPath = @tornado + "access/"
    @invoices = @tornado + "invoices/display_invoice/"
    @paypalExpressPath = @tornado + "payments/paypal_express/"
    @contact = contacts(:email_contact)
    
  end
  
  def teardown
    end_email_server
    @user.teardown
  end
  
  # Create an invoice, code is based on previous tests
  # Customer has a contact that has email autotest@INNOV-TESTEMAIL.dev.peachtree.com
  # Send the invoice, then sleep
  # Read the emails from the web server and check the email fields
  def test_email_invoice_with_HTML_link
    u = User.find(:first, :conditions => {:sage_username => "email_user"})
    u = complete_profile_for(u)
    u.profile.save!
    u.save!
    
    enter_invoice()
    click_send()

    enter_recipient_and_message


    deliverable_id = @user.hidden(:id, "delivery_deliverable_id").value
    
    message_id = @user.wait_for_delivery_of(deliverable_id, "send invoice") do    
      @user.button(:value, "Send").click
      @user.wait
    end

    mail = get_last_sent_email
   
    assert_match /http:\/\/.+\/access\/.+$/, mail.body, "mail should have an access link"

    @accessLink = mail.body[/http:\/\/.+\/access\/.+$/].chomp

    standard_asserts(mail)

    follow_invoice_link()
  
  end # test_email_invoice_with_HTML_link
  
if !$paypal_hidden  
  def test_email_invoice_with_HTML_link_and_paypal_link
    
    enter_invoice()
    click_send()

    # set the contact email, maybe this will be done automatically later
    @user.populate(@user.b.text_field(:id, "delivery_recipients"),(@contact.email))
    @user.populate(@user.b.text_field(:id, "delivery_body"),(@description))
    @user.b.checkbox(:id, "delivery[mail_options][include_direct_payment]").click

    # get the deliverableId from a hidden field and use later to read the deliveries table
    deliverable_id = @user.hidden(:id, "delivery_deliverable_id").value
    
    message_id = @user.wait_for_delivery_of(deliverable_id, "send invoice") do    
      @user.button(:value, "Send").click
      @user.wait
    end

    mail = get_last_sent_email
  
    assert_match /http:\/\/.+\/access\/.+$/, mail.body, "mail should have an access link"
    @accessLink = mail.body[/http:\/\/.+\/access\/.+$/].chomp

    standard_asserts(mail)    
    # check the paypal link
    assert_match(/To pay this invoice by Paypal Express, go to:/, mail.body, "the email content should include 'To pay this invoice by Paypal Express, go to:'")
    assert_match(/#{@paypalExpressPath}/, mail.body, "the email content should include a link starting with {#@paypalExpressPath}")  
    
  end # test_email_invoice_with_HTML_link_and_paypal_link
end

  def test_should_choose_contacts

    u = User.find(:first, :conditions => {:sage_username => "email_user"})
    u = complete_profile_for(u)
    u.profile.save!
    u.save!
    
    customer = add_valid_customer(users(:email_user), {:contacts => false})
    invoice = add_valid_invoice(users(:email_user), {:customer => customer})

    puts "created invoice: #{invoice.id}"
    
    @user.shows_invoice(invoice.id)
    click_send
    @user.wait_until_exists('contacts-multi-chooser-opener')
    @user.link(:id, 'contacts-multi-chooser-opener').click
    assert @user.div(:text, "No Contacts have been entered for this customer").exists?, "at first, the invoice's customer has no contacts to choose from"


    contact_1 = add_valid_contact(customer)
    contact_2 = add_valid_contact(customer)
    contact_3 = add_valid_contact(customer)


    @user.shows_invoice(invoice.id)
    click_send
    @user.wait_until_exists('contacts-multi-chooser-opener')
    @user.link(:id, 'contacts-multi-chooser-opener').click
    assert @user.ul(:id, 'contacts-multi-chooser').exists?
    assert_equal 4, @user.ul(:id, 'contacts-multi-chooser').lis.length, 'contacts chooser should have 3 addresses plus the done button = 4 lis'
    
    # seems that references to objects do not remain valid as document changes!
    cb1 = "invoice_contacts_#{contact_1.id}"
    cb2 = "invoice_contacts_#{contact_2.id}"
    cb3 = "invoice_contacts_#{contact_3.id}"
        

    @user.checkbox(:id, cb2).set(true)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("#{contact_2.formatted_email}")

    @user.checkbox(:id, cb3).set(true)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("#{contact_2.formatted_email}, #{contact_3.formatted_email}")

    @user.checkbox(:id, cb2).set(false)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("#{contact_3.formatted_email}")
    @user.checkbox(:id, cb3).set(false)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("")

    @user.populate(@user.text_field(:id, 'delivery_recipients'), "test@bob.com")
    @user.checkbox(:id, cb1).set(true)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("test@bob.com, #{contact_1.formatted_email}")
    @user.checkbox(:id, cb3).set(true)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("test@bob.com, #{contact_1.formatted_email}, #{contact_3.formatted_email}")
    @user.checkbox(:id, cb2).set(true)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("test@bob.com, #{contact_1.formatted_email}, #{contact_3.formatted_email}, #{contact_2.formatted_email}")
    @user.checkbox(:id, cb1).set(false)
    @user.wait
    
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("test@bob.com, #{contact_3.formatted_email}, #{contact_2.formatted_email}")
    @user.checkbox(:id, cb3).set(false)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("test@bob.com, #{contact_2.formatted_email}")
    @user.checkbox(:id, cb2).set(false)
    @user.wait
    assert @user.text_field(:id, 'delivery_recipients').verify_contains("test@bob.com")

  end
  
private

  def standard_asserts(mail, recipients = nil)
    recipients ||= @user.autotest_email
    # check the from, to, subject, content    
    assert_equal(@user.admin_email, mail.from.first, "the email from should be #{@user.admin_email}")
    assert_equal(@user.autotest_email, mail.to.first, "the email to should be #{@user.autotest_email}")
    assert mail.subject.include?("New invoice from"), "the email subject should be new invoice from"
    assert(mail.body.include?(@description), "the email content should include #{@description}")
  end

  def follow_invoice_link
    puts "@accessLink: #{@accessLink.inspect}"

    @user.b.goto(@accessLink)
    
    #get the access key
    segments = @accessLink.split('/')
    accessKey = segments.last

    ak = AccessKey.find_by_key(accessKey)
    assert_not_nil(ak, "test should have an access key record with key #{accessKey}")
    
    keyableId = ak.keyable_id
    invoice = Invoice.find(keyableId)
        
    # get the invoice number

    linkInvoiceNumber = @user.span(:id, "invoice_unique").text
        
    assert_not_nil(invoice, "test should have an invoice record with key #{invoice}")    
    
    assert_equal(linkInvoiceNumber, invoice.unique, "the invoice number #{linkInvoiceNumber} on the link to page should be the invoice number #{invoice.id} referred to by the access key")
    assert_equal(linkInvoiceNumber, @invoiceNumber, "the invoice number #{linkInvoiceNumber} should be the same as the original invoice number #{@invoiceNumber}")
  end

 
  def enter_invoice
     # Add an Invoice
    assert_difference 'Invoice.count' do
      
      enter_invoice_info()
      enter_customer_info()
      enter_line_items()
   
    end #assert difference

    @user.b.wait
  end 
  
  def enter_invoice_info
    #Create new Invoice and fill it up
    @user.creates_new_invoice
    
    # Invoice Info
    @invoiceNumber = "Email-001"
    @description = "Email-001 Invoice Sent as HTML Link"
    
    @user.sets_invoice_info(
      :unique => @invoiceNumber,
      :date => "2007-11-27",
      :reference => @invoiceNumber,
      :description => @description
    )
  end
  
  def enter_customer_info
    #Customer Info 
      @user.enter_new_customer( 
        :name => "Test 21 Customer"
      )    
  end
  

  def enter_line_items
    # quantity and price initial values   
    quantity = 20
    price = 4.00
  
    # Add line items
    (1..@number_of_line_items).each do | i |
      
      if i == 1 
         @user.edits_line_item(i, 
          :unit => "Item A" + i.to_s,
          :description => "Description for Item A" + i.to_s,
          :quantity => quantity.to_s,
          :price => price.to_s)
      else
        assert_equal i, @user.adds_line_item(
          :unit => "Item A" + i.to_s,
          :description => "Description for Item A" + i.to_s,
          :quantity => quantity.to_s,
          :price => price.to_s)
      end
      
      quantity += 1
      price += 1          
    end
    
    # Submit and verify
    assert_difference 'LineItem.count', @number_of_line_items do
      @user.submits        
    end
  end
  
  def click_send
    #tries to find the draft status string
    assert @user.b.contains_text("Draft")
    #send the invoice
    @user.b.link(:text, "Send").click
    @user.b.wait
    # no status on page
    # assert @user.b.contains_text("sent")
  end
  
  def enter_recipient_and_message
    # set the contact email, maybe this will be done automatically later
    @user.wait_until_exists("delivery_recipients")
    @user.populate(@user.b.text_field(:id, "delivery_recipients"),(@contact.email))
    @user.populate(@user.b.text_field(:id, "delivery_body"),(@description))
  end
  
    def complete_profile_for(user)
      user.profile.company_name = "Company Name"
      user.profile.company_address1 = "Address 1"
      user.profile.company_city = "Vancouver"
      user.profile.company_country = "Canada"
      user.profile.company_state = "British Columbia"
      user.profile.company_postalcode = "V1V 1V1"
      user.profile.company_phone = "123 456 7890"
      return user
    end
   
end
