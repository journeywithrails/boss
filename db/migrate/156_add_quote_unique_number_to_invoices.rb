class AddQuoteUniqueNumberToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :quote_unique_number, :integer
  end

  def self.down
    remove_column :invoices, :quote_unique_number
  end
end
