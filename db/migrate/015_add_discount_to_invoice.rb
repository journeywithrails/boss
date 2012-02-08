class AddDiscountToInvoice < ActiveRecord::Migration
def self.up
    add_column :invoices, :discount_amount, :decimal, :precision => 8, :scale => 2
    add_column :invoices, :discount_percent, :decimal, :precision => 8, :scale => 2
    add_column :invoices, :total, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    remove_column :invoices, :discount_amount
    remove_column :invoices, :discount_percent
    remove_column :invoices, :total
  end
end
