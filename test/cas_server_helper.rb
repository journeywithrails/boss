class CasServerHelper
  class << self
    def cas_login_url
      CASClient::Frameworks::Rails::Filter.client.login_url
    end
    
    def ping_server
      res = nil
      ok = false
      begin
        url = ::CasServerHelper.cas_login_url
        res = ::CasServerHelper.read_url(url)
      rescue Exception => e
        return false
      end
      return res && (res.code == "200")
    end
    
    def read_url(url, limit = 10)
      raise "Too Many Redirects" if limit == 0
      uri = URI.parse url
      server = Net::HTTP.new uri.host, uri.port
      server.use_ssl = uri.scheme == 'https'
      server.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = server.get uri.request_uri

      case response
      when Net::HTTPSuccess then response['host'] = uri.host; response['path'] = uri.path; response
      when Net::HTTPRedirection then self.get_data(response['location'], limit - 1)
      else
        response.error!
      end
    end
  end
end