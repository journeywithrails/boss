module NewBrowsalsHelper
  def xml_metadata(object)
    object.to_xml(:only => [], :methods => [:metadata], :skip_instruct => true).gsub(/^/, '  ') if object
  end

  def current_url
    "<current-url>#{ @url_for_browsal }</current-url>"
  end

  def user_info
    if api_token.has_user_info?
      <<-eof
      <user>
        <login>#{ api_token.user.sage_username }</login>
        <password>#{ api_token.password }</password>
      </user>
      eof
    end
  end

  def explain_error
    if api_token.complete?
      _('Your session has already been completed.')
    elsif api_token.closed?
      _('Your session has been cancelled, please use Simply Accounting to begin a new one if needed.')
    else
      _('The requested page is not allowed during your current operation.')
    end
  end
end
