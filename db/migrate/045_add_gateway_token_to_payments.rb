class AddGatewayTokenToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :gateway_token, :string
  end

  def self.down
    remove_column :payments, :gateway_token
  end
end
