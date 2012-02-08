class AddSupercededByToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :superceded_by_id, :integer
  end

  def self.down
    remove_column :invoices, :superceded_by_id
  end
end
