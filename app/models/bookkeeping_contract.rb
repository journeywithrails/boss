class BookkeepingContract < ActiveRecord::Base
  belongs_to :bookkeeping_client, :class_name => 'Biller'
  belongs_to :bookkeeper
  
  belongs_to :invitation
end
