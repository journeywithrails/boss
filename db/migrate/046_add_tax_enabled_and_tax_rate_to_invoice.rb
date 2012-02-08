class AddTaxEnabledAndTaxRateToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :tax_1_enabled, :boolean
    add_column :invoices, :tax_1_rate, :decimal, :precision => 8, :scale => 2
    add_column :invoices, :tax_2_enabled, :boolean
    add_column :invoices, :tax_2_rate, :decimal, :precision => 8, :scale => 2
    
    Invoice.update_all("tax_1_enabled = false, tax_2_enabled = false, tax_1_rate = 0.0, tax_2_rate = 0.0")
  end

  def self.down
    remove_column :invoices, :tax_1_enabled
    remove_column :invoices, :tax_1_rate
    remove_column :invoices, :tax_2_enabled
    remove_column :invoices, :tax_2_rate
  end
end
