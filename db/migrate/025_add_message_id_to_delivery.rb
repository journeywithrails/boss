class AddMessageIdToDelivery < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :message_id, :string
  end

  def self.down
    remove_column :deliveries, :message_id
  end
end
