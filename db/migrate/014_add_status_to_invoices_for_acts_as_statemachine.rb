class AddStatusToInvoicesForActsAsStatemachine < ActiveRecord::Migration
  def self.up
    add_column :invoices, :status, :string, :default => 'draft'
    
    Invoice.update_all("status = 'draft'")
  end

  def self.down
    remove_column :invoices, :status
  end
end
