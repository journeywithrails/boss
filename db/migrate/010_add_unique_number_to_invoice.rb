class AddUniqueNumberToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :unique_number, :integer
  end

  def self.down
    remove_column :invoices, :unique_number
  end
end
