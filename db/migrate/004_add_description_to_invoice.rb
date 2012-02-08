class AddDescriptionToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :description, :text
  end

  def self.down
    remove_column :invoices, :description
  end
end
