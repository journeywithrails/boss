class ConvertExistingCountryNames < ActiveRecord::Migration
  include ActionView::Helpers::FormOptionsHelper
  
  def self.up
    User.find(:all).each do |user|
      profile = user.profile
      if COUNTRIES.find {|@country| @country[0] == profile.company_country }
          profile.company_country = @country[1]
          profile.save
      else
        RAILS_DEFAULT_LOGGER.warn "User ID:#{user.id} Country:#{user.profile.company_country} could not be converted."
        profile.company_country = ""
        profile.save
      end
    end
  end

  def self.down
  end
end
