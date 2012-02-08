
module FeedbackHelper
  def am_i_current_owner?(owner_id)

    if !owner_id.blank? and (!(owner_id == 0)) and (User.find(owner_id).sage_username == current_user.sage_username )
      return _("Yes")
    else
      return _("No")
    end
  end
end
