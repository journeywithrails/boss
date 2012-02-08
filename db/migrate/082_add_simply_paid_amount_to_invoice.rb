class AddSimplyPaidAmountToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :simply_paid_amount, :decimal, :precision => 8, :scale => 2, :default => 0
  end

  def self.down
    remove_column :invoices, :simply_paid_amount
  end
end
