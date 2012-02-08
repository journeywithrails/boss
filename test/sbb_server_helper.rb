module SbbUrls
  def sbb_server_url
    Sage::Test::Server.sagebusinessbuilder.url
  end

  def sbb_site_url
    sbb_server_url
  end

  def sbb_login_url
    sbb_server_url + "/user"
  end

  def sbb_logout_url
    sbb_server_url + "/caslogout"
  end

  def sbb_my_profile_url
    sbb_server_url + "/user/"
  end

  def sbb_create_profile_url
    sbb_server_url + "/node/add/profile"
  end

end
  
# extend SageTestSession
class SageTestSession
  include SbbUrls
  
  def ensure_sbb_logged_out
    # TODO: Somehow make sure sbb user is logged out and session is cleared.
    goto_sbb_logout_url
  end
  
end

