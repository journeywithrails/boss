class LongGatewayPasswords < ActiveRecord::Migration
  def self.up
    change_column :user_gateways, :password, :text
  end

  def self.down
    change_column :user_gateways, :password, :string
  end
end
