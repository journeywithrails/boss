class AddDeliveryToApiToken < ActiveRecord::Migration
  def self.up
    add_column :api_tokens, :delivery_id, :integer
  end

  def self.down
    remove_column :api_tokens, :delivery_id
  end
end
