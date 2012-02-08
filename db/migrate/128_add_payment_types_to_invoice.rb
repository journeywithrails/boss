class AddPaymentTypesToInvoice < ActiveRecord::Migration
  def self.up
    add_column 'invoices', 'payment_types', :string
  end

  def self.down
    remove_column 'invoices', 'payment_types'
  end
end
