$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

#test cases for user login
class RecurringInvoicesTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :line_items, :customers

  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
  end

  def teardown
    @user.teardown
  end

  def test_user_creates_recurring_invoice_successfully
    flunk
    @user.shows_invoice(invoices(:sent_invoice).id)

    @user.link(:id, "setup-schedule").click
    @user.wait
    @user.text_field(:name, "invoice[send_recipients]").populate("test@example.com, test2@example.com")
    @user.button(:id, "lightbox-button-2").click
    @user.wait
    assert_match /Recurring invoice created successfully/, @user.text
  end

  def test_shows_validation_errors
    invoice = Invoice.create(:created_by => users(:basic_user))
    @user.shows_invoice(invoice.id)
    @user.link(:id, "setup-schedule").click
    @user.wait    
    @user.text_field(:name, "invoice[send_recipients]").populate("emailaddress")
    @user.button(:id, "invoice_submit").click
    @user.wait


#    raise @user.link(:xpath, "//a/").text
#    raise @user.element_by_xpath("//div[@class='calendar_date_select']//div[not(@class) and contains(text(), '1')]").click
    assert @user.element_by_xpath("id('errorExplanation')").exists?

#    raise @user.form(:xpath, "//form[@id='invoice-schedule-form']/").text


#    assert_select "form#invoice_schedule #errorExplanation ul"


  end

end
