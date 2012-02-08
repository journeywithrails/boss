class AddMailNameToDelivery < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :mail_name, :string
    add_column :deliveries, :created_by_id, :integer
  end

  def self.down
    remove_column :deliveries, :mail_name
    remove_column :deliveries, :created_by_id
  end
end
