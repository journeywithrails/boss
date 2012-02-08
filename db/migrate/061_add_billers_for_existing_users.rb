class AddBillersForExistingUsers < ActiveRecord::Migration
  def self.up
    #create billers for users that don't have one
    user_list = User.find(:all, :conditions => 'biller_id IS NULL') #_by_biller_id(nil)
    user_list.each do |u|
      bi = u.create_biller
      u.update_attribute("biller_id", bi.id)
    end
  end

  def self.down
  end
end
