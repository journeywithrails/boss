class AddDateRefAndInvoiceNumber < ActiveRecord::Migration
  def self.up
    add_column :invoices, :date, :date
    add_column :invoices, :reference, :string
    add_column :invoices, :unique_name, :string
  end

  def self.down
    remove_column :invoices, :date
    remove_column :invoices, :reference
    remove_column :invoices, :unique_name
  end
end
