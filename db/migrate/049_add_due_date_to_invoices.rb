class AddDueDateToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :due_date, :datetime
  end

  def self.down
    remove_column :invoices, :due_date
  end
end
