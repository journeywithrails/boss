require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../curl_helper'
require 'babel'

class UserApiTest < Test::Unit::TestCase
  
  def setup
    @user_add_url = ::AppConfig.host + "/users.xml" 
    @login = Babel.random_username + "@" + Babel.random_username + ".com"
    
    if Test::Unit::TestCase.is_windows?
      @curl_cmd = "C:\\Program\ Files\\curl\\curl.exe"
      if !File.exists?(@curl_cmd)
        p 'curl.exe is used in UserApiTest. C:\Program Files\curl\curl.exe does not exist.'
        p ''
        p 'download cUrl'
        p 'http://curl.haxx.se/download.html'
        p 'Win32 Generic'
        p 'select the lastest version - eg Win32 2000/XP 7.18.1'
        p 'file is curl-7.18.1-ssl-sspi-zlib-static-bin-w32.zip'
        p 'unzip to C:\Program Files\curl'
        p ''        
        p ''        
        deny false
      end    

    else
      @curl_cmd = `which curl`.chomp
      @curl_cmd = "/usr/local/bin/curl" if @curl_cmd.blank? 
      if !File.exists?(@curl_cmd)
        p 'curl.exe is used in UserApiTest.  /usr/local/bin/curl does not exist'
        p ''        
        p 'download cUrl'
        p 'http://curl.haxx.se/download.html'
        p 'select appropriate zip for OS'
        p 'unzip to /usr/local/bin/curl'
        p ''        
        p ''        
        deny false
    end      
    
    end
  end
  
  def teardown
    
  end
  
  def test_add_user_through_api
    
    xml = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <user>
      <login>#{@login}</login>
      <password>test</password>
      <terms_of_service>1</terms_of_service>
    </user>
XML

    response = curl_add(@curl_cmd, xml, @user_add_url)
    response_xml = REXML::Document.new(response)
    user_login = REXML::XPath.first(response_xml, '/user/login').text
    assert_equal @login, user_login, "the login #{@login} was expected in the response but #{user_login} was found"
    
  end
  
  def test_add_duplicate_user_through_api
    
    xml = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <user>
      <login>#{@login}</login>
      <password>test</password>
      <terms_of_service>1</terms_of_service>
    </user>
XML
    
    response = curl_add(@curl_cmd, xml, @user_add_url)
    response_xml = REXML::Document.new(response)
    user_login = REXML::XPath.first(response_xml, '/user/login').text
    assert_equal @login, user_login, "the login #{@login} was expected in the response but #{user_login} was found"
    
    response = curl_add(@curl_cmd, xml, @user_add_url)
    response_xml = REXML::Document.new(response)
    error_message = REXML::XPath.first(response_xml, '/errors/error').text
    assert_equal "Login has already been used. Please enter a different one", error_message, "Duplicate login did not send back the proper error message"
    
  end  
  
  
  def test_add_user_with_incorrect_terms_of_service_through_api
    
    xml = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <user>
      <login>#{@login}</login>
      <password>test</password>
      <terms_of_service>0</terms_of_service>
    </user>
XML

    response = curl_add(@curl_cmd, xml, @user_add_url)
    response_xml = REXML::Document.new(response)
    error_message = REXML::XPath.first(response_xml, '/errors/error').text
    assert_equal "Must accept terms of service and privacy policy ", error_message, "Did not accept terms and conditions did not send back the proper error message"
    
  end    
  
  def test_add_user_with_incorrect_login_through_api
    
     xml = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <user>
      <login>email</login>
      <password>test</password>
      <terms_of_service>1</terms_of_service>
    </user>
XML

    response = curl_add(@curl_cmd, xml, @user_add_url)
    response_xml = REXML::Document.new(response)
    error_message = REXML::XPath.first(response_xml, '/errors/error').text
    assert_equal "Email must be a valid email address", error_message, "Invalid email did not send back the proper error message"
    
  end    
  
end