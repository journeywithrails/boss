class AddSimplyGuidToCustomerAndInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :simply_guid, :string
    add_column :customers, :simply_guid, :string    
  end

  def self.down
    remove_column :customers, :simply_guid
    remove_column :invoices, :simply_guid
  end
end
