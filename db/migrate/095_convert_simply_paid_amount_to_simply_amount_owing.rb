class ConvertSimplyPaidAmountToSimplyAmountOwing < ActiveRecord::Migration
  def self.up
    rename_column :invoices, :simply_paid_amount, :simply_amount_owing
    # renaming column seems to kill default value
    change_column_default :invoices, :simply_amount_owing, 0
  end

  def self.down
    rename_column :invoices, :simply_amount_owing, :simply_paid_amount
    change_column_default :invoices, :simply_paid_amount, 0
  end
end
