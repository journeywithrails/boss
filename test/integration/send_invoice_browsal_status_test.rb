require "#{File.dirname(__FILE__)}/../test_helper"

class SendInvoiceBrowsalStatusTest < ActionController::IntegrationTest
  include SimplyApiTestHelpers

  def setup
    CASClient::Frameworks::Rails::Filter.stubs(:check_cas_status?).returns(false)
  end
  
  def teardown
    unstub_cas
  end
  
  def test_new_SA_signup_closes_window_at_signup
    api_token, current_url, token_url = initiate_send_invoice('signup')
    extended_session do |user|
      user.get current_url
      user.assert_redirected_to_sam(:theme=>'simply', :service_url => "http://#{host_for_test}/api/simply/newuser/thankyou")
      user.received_close!(token_url)
    end
  end
  
  def test_new_SA_signup_closes_window_at_send_invoice_now_or_later
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      ######### user clicks close on the thank you page
      user.received_close!(token_url)
    end
  end

  def test_new_SA_signup_closes_window_at_preview_invoice
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.preview_invoice!
      ######### user clicks close on the invoice preview page
      user.received_close!(token_url)
    end
  end
  
  def test_new_SA_signup_closes_window_at_invoice_sent
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.preview_invoice!
      user.send_invoice!
      ######### user clicks close on the invoice preview page
      user.received_close!(token_url)
    end
  end
  
  def test_new_SA_signup_clicks_complete_at_invoice_sent
    api_token, current_url, token_url = initiate_send_invoice('signup')
    session_successfully_create_user(api_token, current_url) do |user|
      user.preview_invoice!
      user.send_invoice!
      ######### user clicks close on the invoice preview page
      user.received_complete!(token_url)
    end
  end
  
  def test_SA_login_closes_window_at_login
    api_token, current_url, token_url = initiate_send_invoice('login')
    extended_session do |user|
      user.get current_url
      user.assert_redirected_to_cas_login
      user.received_close!(token_url)
    end
  end
  
  def test_SA_login_closes_window_at_send_invoice_now_or_later
    api_token, current_url, token_url = initiate_send_invoice('login')
    session_successfully_login(api_token, current_url) do |user|
      user.received_close!(token_url)
    end
  end
  
  def test_SA_login_closes_window_at_invoice_sent
    api_token, current_url, token_url = initiate_send_invoice('login')
    session_successfully_login(api_token, current_url) do |user|
      user.send_invoice!
      user.received_close!(token_url)
    end
  end
  
  def test_SA_login_clicks_complete_at_invoice_sent
    api_token, current_url, token_url = initiate_send_invoice('login')
    session_successfully_login(api_token, current_url) do |user|
      user.send_invoice!
      user.received_complete!(token_url)
    end
  end  
end
