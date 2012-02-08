class AddCurrencyToUserGateway < ActiveRecord::Migration
  def self.up
    add_column :user_gateways, :currency, :string
  end

  def self.down
    remove_column :user_gateways, :currency
  end
end
