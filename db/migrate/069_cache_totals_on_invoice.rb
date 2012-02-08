class CacheTotalsOnInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :calculated_at, :datetime
    add_column :invoices, :tax_1_amount, :decimal, :precision => 8, :scale => 2, :default => 0
    add_column :invoices, :tax_2_amount, :decimal, :precision => 8, :scale => 2, :default => 0
    add_column :invoices, :subtotal_amount, :decimal, :precision => 8, :scale => 2, :default => 0
    rename_column :invoices, :total, :total_amount
    change_column_default :invoices, :total_amount, 0
    change_column_default :taxes, :amount, 0
  end

  def self.down
    rename_column :invoices, :total_amount, :total
    remove_column :invoices, :calculated_at
    remove_column :invoices, :tax_1_amount
    remove_column :invoices, :tax_2_amount
    remove_column :invoices, :subtotal_amount
  end
end
