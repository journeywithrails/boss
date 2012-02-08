class AddStiToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :type, :string
    create_table :invoice_files do |t|
      t.column :simply_accounting_invoice_id,  :integer
      t.column :content_type, :string
      t.column :filename, :string    
      t.column :thumbnail, :string 
      t.column :size, :integer
      t.column :width, :integer
      t.column :height, :integer
    end
  end

  def self.down
    remove_column :invoices, :type
    drop_table :invoice_files
  end
end
