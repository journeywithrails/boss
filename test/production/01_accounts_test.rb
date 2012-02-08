$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/production_test_helper'

class AccountsTest < SageProductionTestCase
include AcceptanceTestSession

  def setup
    admin.delete_user_if_exists(:ping)
    @b = watir_session.with(:ping)
  end
  
  def teardown 
    @b.teardown
    $log_on = false
  end
  
  def test_happy_path
    verify_create_user
    verify_receives_new_account_email
    admin.activate_user(:ping)
    verify_log_off
    verify_log_on
    
    verify_uploads_logo

    verify_invoices_overview_is_empty
    
    verify_creates_new_invoice
    verify_creates_new_customer
    verify_creates_new_contact

    verify_creates_invoice_pdf
    verify_sends_invoice
    verify_records_payment

    verify_invites_bookkeeper
  end
  
  def verify_create_user
    
    @b.goto_create_account_url
    
    STDIN.getc if $log_on 
    
    @b.text_field(:id,"user_login").set( @b.user.login)
    @b.text_field(:id,"user_password").set( @b.user.password )
    @b.text_field(:id,"user_password_confirmation").set( @b.user.password )
    @b.checkbox(:id, "user_terms_of_service").set("1" )
    @b.wait
        
    @b.button(:value, "Sign up").click    
    @b.wait
    
    STDIN.getc if $log_on

    #look for the flash message to see if the account is created
    assert @b.contains_text("Thanks for signing up")
  end

  def verify_receives_new_account_email
    puts "verify_receives_new_account_email not yet implemented"
  end

  def verify_log_off
    puts "verify_log_off not yet implemented"
  end

  def verify_log_on
    puts "verify_log_on not yet implemented"
  end

  
  def verify_uploads_logo
    puts "verify_uploads_logo not yet implemented"
  end


  def verify_invoices_overview_is_empty
    puts "verify_invoices_overview_is_empty not yet implemented"
  end

  
  def verify_creates_new_invoice
    puts "verify_creates_new_invoice not yet implemented"
  end

  def verify_creates_new_customer
    puts "verify_creates_new_customer not yet implemented"
  end

  def verify_creates_new_contact
    puts "verify_creates_new_contact not yet implemented"
  end


  def verify_creates_invoice_pdf
    puts "verify_creates_invoice_pdf not yet implemented"
  end

  def verify_sends_invoice
    puts "verify_sends_invoice not yet implemented"
  end

  def verify_records_payment
    puts "verify_records_payment not yet implemented"
  end


  def verify_invites_bookkeeper
    puts "verify_invites_bookkeeper not yet implemented"
  end


end