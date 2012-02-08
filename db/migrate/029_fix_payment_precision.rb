class FixPaymentPrecision < ActiveRecord::Migration
  def self.up
    remove_column :payments, :amount
    add_column :payments, :amount, :decimal, :precision => 8, :scale => 2

    remove_column :pay_applications, :amount
    add_column :pay_applications, :amount, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    remove_column :payments, :amount
    add_column :payments, :amount, :decimal

    remove_column :pay_applications, :amount
    add_column :pay_applications, :amount, :decimal
  end
end
