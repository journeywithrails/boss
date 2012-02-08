class Spsubscription < ActiveRecord::Base
  
  accepted_codes = ['BB-01']
  if ENV['RAILS_ENV']=='test'
    #The following codes are required for unit tests.
    accepted_codes += ['Product1', 'Product2', 'ProductCode']
    #The following codes are required for running proveng unit tests though ActiveResource.
    accepted_codes += ['10', 'I-02', 'I-03', 'I-04', 'ServiceCode4', 'ServiceCode5']
  end

  belongs_to :spaccount
  has_friendly_id :service_code
  validates_uniqueness_of :service_code, :scope => "spaccount_id"
  validates_uniqueness_of :transaction_id    

  validates_inclusion_of :service_code, :in => accepted_codes, :message => "%{fn} should be one of #{accepted_codes.inspect}"
  validates_inclusion_of :qty, :in => [0, 1], :message => "%{fn} should be 0 or 1"

  def before_save
    user = self.spaccount.user

    if self.qty > 0
      user.active = true
      user.activate #saves user
    else
      user.active = false
      user.save
    end
    
    raise ActiveRecord::RecordInvalid, user unless user.valid? 
    true
  end
        
end
