require File.dirname(__FILE__) + '/../test_helper'

class MailOutputTest < Test::Unit::TestCase
  fixtures :users
  def setup
    sleep 5 #don't overload the mailer
    @rec = "richard@10.152.17.65"
  end
  
  def test_referral_mail_ssan_contest
    ReferralMailer.deliver_referral("1234567890abcdef", "My Name", @rec, "Your Name", @rec, ::AppConfig.host_with_port, true)
    assert true
  end
  
  def test_referral_mail_soho_contest
    ReferralMailer.deliver_referral("1234567890abcdef", "My Name", "", "Your Name", @rec, ::AppConfig.host_with_port, false)
    assert true
  end
  
  def test_referral_mail_ssan_no_contest
    flip_contest
    ReferralMailer.deliver_referral("1234567890abcdef", "My Name", @rec, "Your Name", @rec, ::AppConfig.host_with_port, true)
    flip_contest
    assert true
  end
  
  def test_referral_mail_soho_no_contest
    flip_contest
    ReferralMailer.deliver_referral("1234567890abcdef", "My Name", @rec, "Your Name", @rec, ::AppConfig.host_with_port, false)
    flip_contest
    assert true
  end
  
  
  def flip_contest
    ::AppConfig.contest.bybs = !::AppConfig.contest.bybs    
  end
end
