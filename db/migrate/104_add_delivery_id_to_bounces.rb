class AddDeliveryIdToBounces < ActiveRecord::Migration
  def self.up
    add_column :bounces, :delivery_id, :integer
  end

  def self.down
    remove_column :bounces, :delivery_id
  end
end
