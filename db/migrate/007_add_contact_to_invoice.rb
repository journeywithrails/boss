class AddContactToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :contact_id, :integer
  end

  def self.down
    remove_column :invoices, :contact_id
  end
end
