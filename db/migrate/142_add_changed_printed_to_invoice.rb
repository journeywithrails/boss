class AddChangedPrintedToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :changed_printed, :boolean, :default => false
    
    puts "Searching for changed_printed invoices..."
    @invoices = Invoice.find(:all, :conditions => {:status => "changed_printed"})
    puts "#{@invoices.size} invoices found."
    puts "updating invoice states..."
    @invoices.each do |invoice|
      invoice.status = "changed"
      invoice.changed_printed = true
      invoice.save_without_validation
    end
    
  end

  def self.down
    remove_column :invoices, :changed_printed
  end
end
