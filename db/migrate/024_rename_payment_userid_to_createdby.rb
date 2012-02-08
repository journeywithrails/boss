class RenamePaymentUseridToCreatedby < ActiveRecord::Migration
  def self.up
    add_column :payments, :created_by_id, :integer
    remove_column :payments, :user_id
    
    add_column :pay_applications, :created_by_id, :integer
  end

  def self.down
    remove_column :payments, :created_by_id
    add_column :payments, :user_id, :integer
    
    remove_column :pay_applications, :created_by_id
  end
end
