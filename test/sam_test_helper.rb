module SamTestHelper
  include SamSupportHelper
  
  # asserts that response was directed to the SageAccountManager signup url set in appconfig
  def assert_redirected_to_sam(options={})
    assert_response :redirect
    sam_url = signup_url(options)
    assert_equal(sam_url, redirect_to_url)
  end
  
  # parses out the service url from an url with a service param
  def sam_service_url_from_redirect_url redirect_url
    uri = URI.parse(redirect_url)
    q = ActionController::AbstractRequest.parse_query_parameters(uri.query)
    q["service"]
  end
  
  
  def assert_sam_url_with_service(service_url, url, options = {})
    in_sam_url = url.split('?').first
    assert_equal signup_url(:service_url => false).split('?').first, in_sam_url, "should have an url to sam"
    uri = URI.parse(url)
    q = ActionController::AbstractRequest.parse_query_parameters(uri.query)
    q_service = q["service"]
    if service_url.is_a?(Regexp)
      assert_match service_url, q_service, "service url should have matched"
    else
      assert_equal service_url, q_service, "service should have been #{service_url}"
    end
  end
end