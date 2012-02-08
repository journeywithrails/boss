module AcceptanceTestUrls
  def home_url
    site_url
  end
  
  def create_account_url
    site_url + "/users/new"
  end

  def activate_url
    site_url + "/activate"
  end

  def new_invoice_site_url
    site_url + "/invoices/new"
  end

  def new_customer_url
    site_url + "/customers/new"
  end
  
  def edit_customer_url(id)
    site_url + "/customers/#{id}/edit"
  end
  
  def invoice_url(id)
    site_url + "/invoices/#{id}"      
  end
  
  def invoices_url
    site_url + "/invoices"      
  end
  
  def invoice_edit_url(id)
    site_url + "/invoices/#{id}/edit"      
  end

  def logoff_url
    site_url + "/logout"
  end

  def cas_login_url
    CASClient::Frameworks::Rails::Filter.client.login_url
  end
  
  def cas_logout_url
    CASClient::Frameworks::Rails::Filter.client.logout_url
  end
  
  def login_url
    site_url + "/session/new"
  end

  def current_session_url
    site_url + "/current_session"
  end

  def signup_url
    site_url + "/users/new"
  end

  def stub_logged_in_with_cas_url
    site_url + "/session/test_login/"
  end
  
  def stub_logged_out_with_cas_url
    site_url + "/session/test_logout"
  end
  
  def stub_first_login_url
    site_url + "/session/test_first_login"
  end

  def stub_gateway_url
    site_url + "/session/test_gateway"
  end
  
  def profile_url
    site_url + "/profiles"
  end
  
  def referral_url
    site_url + "/invite_a_friend"
  end
  
  def contest_taf_url
    site_url + "/contest/tell_a_friend"
  end
  
  def contest_signup_url
    site_url + "/contest/signup"
  end
  
  def contest_url
    site_url + "/contest/"      
  end
  
  def rac_contest_url
    site_url + "/professionals/"      
  end
  
  def rac_contest_tell_a_client_url
    site_url + "/tell_a_client"
  end
  
  def referral_welcome_url(code = nil)
    url = site_url + "/contest"
    if code
      url += "?referral_code=#{code}"
    end
    url
  end
end