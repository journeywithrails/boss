class AddUsingGatewaysToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :using_gateways, :string
  end

  def self.down
    remove_column :invoices, :using_gateways
  end
end
