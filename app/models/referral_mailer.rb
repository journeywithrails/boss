class ReferralMailer < ActionMailer::Base

  helper :application
  include SamSupportHelper
  helper LocalizationHelper
  
  def referral(referral, url_base, ssan=nil)
    content_type 'text/html'
    @body[:referral] = referral
    @body[:url_base] = url_base
    @body[:ssan] = ssan
    @body[:video_tour_url] = "#{::AppConfig.host}/tour?referral_code=#{referral.referral_code}"
    @body[:bookkeeper_url] = "#{::AppConfig.host}/bookkeeper?referral_code=#{referral.referral_code}"
    @recipients = referral.friend_email
    @from       = ::AppConfig.mail.from
    headers     "Reply-to" => ::AppConfig.mail.from
    @sent_on    = Time.now
    @headers    = {}

  end
end
