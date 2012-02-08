class AddDiscountSummaryFieldToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :discount, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    remove_column :invoices, :discount    
  end
end
