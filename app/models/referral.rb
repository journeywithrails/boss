require 'digest/sha1'

class Referral < ActiveRecord::Base
  belongs_to :user # this is the user 
  validates_email_format_of :referring_email, :friend_email
  validates_length_of :referring_name, :within => 1..100
  validates_presence_of :referring_name, :referring_email, :friend_email
  validates_uniqueness_of :friend_email, :case_sensitive => false, :scope => :referring_email
  before_create :create_referral_code
  public
  
  def mail_quota_exceeded?
    a = Referral.find_by_sql(["SELECT sent_at FROM referrals WHERE friend_email = ? ORDER BY sent_at DESC", self.friend_email])
    if a.size > 1
      if !a[0].sent_at.blank? and a[0].sent_at > Time.now-1.day and a[1].sent_at > Time.now-1.day
        return true
      end
    end
    return false
  end
  
  def already_accepted?
    a = Referral.find_by_sql(["SELECT * FROM referrals WHERE friend_email = ? AND accepted_at is not null", self.friend_email])
    if !a.empty?
      return true
    else
      return false
    end
    
  end
  def duplicate_email?
    if self.referring_email.blank? or self.friend_email.blank?
      return false
    end
    a = Referral.find_by_sql(["SELECT * FROM referrals WHERE referring_email = ? and friend_email = ?", self.referring_email, self.friend_email])
    if a.size > 0
      return true
    else
      return false
    end
  end
  
  protected
  def create_referral_code
    self.referral_code = Digest::SHA1.hexdigest("--#{self.friend_email}--#{srand}--")
  end
end