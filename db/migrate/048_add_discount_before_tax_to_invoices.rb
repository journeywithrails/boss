class AddDiscountBeforeTaxToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :discount_before_tax, :boolean
    Invoice.update_all("discount_before_tax = false")
  end

  def self.down
    remove_column :invoices, :discount_before_tax
  end
end
