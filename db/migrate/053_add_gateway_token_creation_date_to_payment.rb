class AddGatewayTokenCreationDateToPayment < ActiveRecord::Migration
  def self.up
    add_column :payments, :gateway_token_date, :datetime
  end

  def self.down
    remove_column :payments, :gateway_token_date
  end
end
