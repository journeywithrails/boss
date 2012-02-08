class AddRecurringIdToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :recurring_invoice_id, :integer
  end

  def self.down
    remove_column :invoices, :recurring_invoice_id
  end
end
