class AddCachedPaidAndOwedAmountsToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :paid_amount, :decimal, :precision => 8, :scale => 2, :default => 0
    add_column :invoices, :owing_amount, :decimal, :precision => 8, :scale => 2, :default => 0
    
    #this will take forever and a half to run on prod db...
    invoices = Invoice.find(:all)
    invoices.each do |inv|
      inv.calculate_discounted_total
      inv.save(false)
    end
  end

  def self.down
    remove_column :invoices, :paid_amount
    remove_column :invoices, :owing_amount
  end
end
