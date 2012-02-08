class RefactorDiscountFieldsOnInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :discount_type, :string
    add_column :invoices, :discount_value, :decimal, :precision => 8, :scale => 2
    remove_column :invoices, :discount_percent
    remove_column :invoices, :discount
  end

  def self.down
    remove_column :invoices, :discount_type
    remove_column :invoices, :discount_value
    add_column :invoices, :discount, :decimal, :precision => 8, :scale => 2
    add_column :invoices, :discount_percent, :decimal, :precision => 8, :scale => 2
  end
end
