class AddDeletedAtToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :deleted_at, :datetime
  end

  def self.down
    remove_column :invoices, :deleted_at
  end
end
