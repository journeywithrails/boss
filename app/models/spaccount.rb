class Spaccount < ActiveRecord::Base
#require 'uuidtools'
  
  has_friendly_id :spaccount_name
  validates_uniqueness_of :spaccount_name
  validates_uniqueness_of :transaction_id  
  has_many :spsubscriptions, :dependent => :destroy
  belongs_to :user
  
  def self.new_user_params(params = {})
    sage_username = params[:spaccount_name]
    sage_username ||= params[:email].split('@').first if params[:email]
    user_params = {
      :sage_username => sage_username,
      :email => params[:email],
      :crypted_password => '*', #UUIDTools::UUID.random_create.hexdigest,
      :signup_type => "pe", #from provisioning engine
      :terms_of_service => true
    }
  end
  
  def new_profile_params(more_params = {})
    params = {
      :profile_company_name => company,
      :profile_contact_name => "#{first_name} #{last_name}",
      :profile_company_address1 => address,
      :profile_company_city => city,
      :profile_company_state => state_prov,
      :profile_company_country => country,
      :profile_company_postalcode => zip_postal,
      :profile_company_phone => phone
    }
    params.merge(more_params)
  end
end
