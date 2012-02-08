class AddTaxNamesToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :tax_1_name, :string
    add_column :invoices, :tax_2_name, :string
  end

  def self.down
    remove_column :invoices, :tax_1_name
    remove_column :invoices, :tax_2_name
  end
end
