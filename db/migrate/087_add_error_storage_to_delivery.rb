class AddErrorStorageToDelivery < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :error_details, :text
  end

  def self.down
    remove_column :deliveries, :error_details
  end
end
