module ReferralHelper
  def highlight_referring_name_on_error
    return 'error_in_cell' unless (@valid_referring_name != false) or !@friend_invited    
  end
  
  def highlight_referring_email_on_error
    return 'error_in_cell' unless (@valid_referring_email != false) or !@friend_invited
  end
  
  def highlight_friend_name_on_error
    return 'error_in_cell' unless (!@error or !@friend_invited or !@referrals or @referrals[@i].blank? or @referrals[@i].valid_for_attributes?(:friend_name) != false)
  end
  
  def highlight_friend_email_on_error
    return 'error_in_cell' unless (!@error or !@friend_invited or !@referrals or @referrals[@i].blank? or @referrals[@i].valid_for_attributes?(:friend_email) != false)
  end
  
  def repeat_referrer_name_if_error
    return @referring_name unless @referring_name.blank?
  end
  
  def repeat_referrer_email_if_error
    return @referring_email unless @referring_email.blank?
  end
  
  def repeat_friend_name_if_error
    return @referrals[@i].friend_name unless (!@error or @referrals[@i].blank? or @referrals[@i].friend_name.blank?) 
  end
  
  def repeat_friend_email_if_error
    return @referrals[@i].friend_email unless (!@error or @referrals[@i].blank? or @referrals[@i].friend_email.blank?)
  end
  

end
