require File.expand_path(File.dirname(__FILE__) + '/cas_server_helper')
require File.expand_path(File.dirname(__FILE__) + '/sbb_server_helper')

module CasAcceptanceHelper
  class Test::Unit::TestCase
    include SbbUrls
    
    def ensure_cas_server
      assert ::CasServerHelper.ping_server, "unable to connect to the cas test server at #{::CasServerHelper.cas_login_url}"
    end
    
    def ensure_sbb_server
      assert SbbServerHelper.ping_server(sbb_server_url), "unable to connect to the billingboss server at #{sbb_server_url}"
    end
  end
end

