class AddAccessKeyIdToDeliveries < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :access_key_id, :integer
  end

  def self.down
    remove_column :deliveries, :access_key_id
  end
end
