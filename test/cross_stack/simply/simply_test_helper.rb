require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/../../acceptance/acceptance_test_helper'
require File.dirname(__FILE__) + '/../../cas_acceptance_helper'
require File.dirname(__FILE__) + '/../sso'

class Test::Unit::TestCase
  def simply
    @simply ||= SimplyStub.new
  end
end

class SimplyStub
  def create_login_browsal(user_email=nil)
    user_email ||= "basic_user@billingboss.com"
    request_xml = simply_request(login_browsal_attrs, user_attrs(user_email))
    parse_create_browsal_response(post(request_xml))
  end
    
  def simply_request(browsal_attributes=nil, user_attributes=nil)
    simply = {
        :version => "Simply-US-16.00.0.0120-071209"
      }      

    simply[:user] = user_attributes if user_attributes
    simply[:browsal] = browsal_attributes if user_attributes
    simply.to_xml(:root => 'simply_request')
  end
  
  
  def login_browsal_attrs
    { 
      :browsal_type => 'SignupBrowsal',
      :start_status => 'login',
      :language => 'en'
    }
  end
    
  def signup_browsal_attrs
    { 
      :browsal_type => 'SignupBrowsal',
      :start_status => 'signup',
      :language => 'en'
    }
  end
  
  def send_invoice_browsal_attrs
    { 
      :browsal_type => 'SendInvoiceBrowsal',
      :start_status => 'login',
      :language => 'en'
    }
  end  
  
  def user_attrs(email)
    {
      :login => email
    }
  end
  
  def uri(path=nil)
    url = Sage::Test::Server.billingboss.url + "/browsals"
    url += "/#{path}" if path
    URI.parse( url )
  end
  
  def post(payload, path=nil)
    url = uri(path)
    request = Net::HTTP::Post.new(url.path)
    request.body = payload
    request.content_type = "application/xml"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
  end

  def parse_create_browsal_response(response)
    as_hash = Hash.from_xml response.body
    browsal = as_hash["signup_browsal"]
    browsal ||= as_hash["send_invoice_browsal"]
    raise "response held no browsal element:\n#{response.body}" if browsal.nil?

    current_url = browsal["current_url"]    
    raise "response held no current url" if current_url.blank?
    match = current_url.match(/browsals\/([^\/]+)\//)
    raise "colud not parse api_token guid from current_url: #{current_url}" unless match
    api_token_guid = match[1]
    return [current_url, api_token_guid]
  end
end

