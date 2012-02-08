require File.dirname(__FILE__) + '/../test_helper'

class LanguagesControllerTest < ActionController::TestCase
  fixtures :users, :invoices
  
  def setup
    stub_cas_logged_out
    @request.env["HTTP_REFERER"] = "http://test.host/last/page/visited"
    @controller = LanguagesController.new
  end
  
  def teardown
    $log_on = false
    GettextLocalize.set_locale("en_us")
  end
  
  def test_should_redirect_back
    xhr :post, :create, :language => "en_us"
    assert_response :success # todo assert ajax redirect
  end
  
  def test_should_change_the_language_for_unregisted_user
    xhr :post, :create, :language => "fr_fr"
    assert_equal @response.cookies["lang"], ["fr_fr"]
  end
  
  def test_should_save_language_to_database_for_logged_in_user
    login_as :basic_user
    xhr :post, :create, :language => "fr_fr"
    current_user = users(:basic_user)
    current_user.reload
    assert_equal "fr_fr", users(:basic_user).language
  end
  
  def test_should_update_client_customer_language_when_viewing_invoice
    invoice = invoices(:invoice_with_profile)
    xhr :post, :create, :invoice_id => invoice.id, :language => "fr_fr"
    assert_equal "fr_fr", invoice.customer.language    
  end
  
  def test_url_access_to_language_for_unregistered_user
    #positive tests
    xhr :get, :show, :id => "en"
    assert_equal ["en"], @response.cookies["lang"]
    xhr :get, :show, :id => "es"
    assert_equal ["es"], @response.cookies["lang"]
    xhr :get, :show, :id => "fr"
    assert_equal ["fr"], @response.cookies["lang"]
    xhr :get, :show, :id => "it"
    assert_equal ["it"], @response.cookies["lang"]
    xhr :get, :show, :id => "ko"
    assert_equal ["ko"], @response.cookies["lang"]
    xhr :get, :show, :id => "ru"
    assert_equal ["ru"], @response.cookies["lang"]
    xhr :get, :show, :id => "pt"
    assert_equal ["pt"], @response.cookies["lang"]
    xhr :get, :show, :id => "pt_BR"
    assert_equal ["pt_BR"], @response.cookies["lang"]
    xhr :get, :show, :id => "zh_CN"
    assert_equal ["zh_CN"], @response.cookies["lang"]
    xhr :get, :show, :id => "zh_HK"
    assert_equal ["zh_HK"], @response.cookies["lang"]
    xhr :get, :show, :id => "zh_TW"
    assert_equal ["zh_TW"], @response.cookies["lang"]
    # negative test
    xhr :get, :show, :id => "en"
    assert_not_equal ["fr"], @response.cookies["lang"]
  end

  def test_url_access_to_language_for_registered_user
    login_as :basic_user
    xhr :post, :create, :language => "es"
    current_user = users(:basic_user)
    current_user.reload
    assert_equal "es", users(:basic_user).language
    assert_not_equal "fr", users(:basic_user).language
  end

end
