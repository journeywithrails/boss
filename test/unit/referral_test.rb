require File.dirname(__FILE__) + '/../test_helper'

class ReferralTest < ActiveSupport::TestCase
  def test_valid_referrals
    r = Referral.new
    
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    assert r.valid?
    
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = ""
    r.friend_email = "bob@abc.com"
    assert r.valid?
  end
  
  def test_invalid_referrals
    r = Referral.new
    
    r.referring_name = "John"
    r.referring_email = ""
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    deny r.valid?

    r.referring_name = "John"
    r.referring_email = "john@"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    deny r.valid?
    
    r.referring_name = ""
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    deny r.valid?
    
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = ""
    r.friend_email = ""
    deny r.valid?
    
    r.referring_name = "John"
    r.referring_email = ""
    r.friend_name = "Bob"
    r.friend_email = "bob@"
    deny r.valid?
    
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = ""
    deny r.valid?
  end
  
  def test_same_referrer_and_friend_invalid
    r = Referral.new
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    assert r.valid?
    r.save!

    r2 = Referral.new
    r2.referring_name = "John2"
    r2.referring_email = "john@abc.com"
    r2.friend_name = "Bob2"
    r2.friend_email = "bob@abc.com"
    deny r2.valid?
  end
  
  def test_same_referrer_valid
    r = Referral.new
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    assert r.valid?
    r.save!

    r2 = Referral.new
    r2.referring_name = "John"
    r2.referring_email = "john@abc.com"
    r2.friend_name = "Bob"
    r2.friend_email = "bob2@abc.com"
    assert r.valid?    
  end
  
  def test_same_friend_valid
    r = Referral.new
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    assert r.valid?
    r.save!

    r2 = Referral.new
    r2.referring_name = "John"
    r2.referring_email = "john2@abc.com"
    r2.friend_name = "Bob"
    r2.friend_email = "bob@abc.com"
    assert r.valid?      
  end
  
  def test_mail_quota
    r = Referral.new
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    r.sent_at = Time.now
    assert r.valid?
    r.save!
    
    deny r.mail_quota_exceeded?
    
    r2 = Referral.new
    r2.referring_name = "John2"
    r2.referring_email = "john2@abc.com"
    r2.friend_name = "Bob"
    r2.friend_email = "bob@abc.com"
    r2.sent_at = Time.now
    assert r2.valid?
    r2.save!
    
    assert r2.mail_quota_exceeded?
    
    r2.sent_at = Time.now-2.days
    r2.save!
    
    deny r2.mail_quota_exceeded?

  end

  def test_already_accepted
    r = Referral.new
    r.referring_name = "John"
    r.referring_email = "john@abc.com"
    r.friend_name = "Bob"
    r.friend_email = "bob@abc.com"
    r.sent_at = Time.now
    r.accepted_at = Time.now
    assert r.valid?
    deny r.already_accepted?
    r.save!
    
    r2 = Referral.new
    r2.referring_name = "John2"
    r2.referring_email = "john2@abc.com"
    r2.friend_name = "Bob"
    r2.friend_email = "bob@abc.com"
    r2.sent_at = Time.now
    assert r2.valid?
    assert r2.already_accepted?

    end
    
    def test_duplicate_email
      r = Referral.new
      r.referring_name = "John"
      r.referring_email = "john@abc.com"
      r.friend_name = "Bob"
      r.friend_email = "bob@abc.com"
      r.sent_at = Time.now
      deny r.duplicate_email?
      r.save!
      
      r2 = Referral.new
      deny r2.duplicate_email?
      r2.referring_name = "John"
      r2.referring_email = "john@abc.com"
      r2.friend_name = "Bob"
      r2.friend_email = "bob@abc.com"
      assert r2.duplicate_email?
      
    end

end
