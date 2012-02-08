class CreateTaxes < ActiveRecord::Migration
  def self.up
    create_table :taxes do |t|
      t.integer :parent_id
      t.decimal :rate, :precision => 8, :scale => 2
      t.string  :profile_key
      t.string  :name
      t.boolean :included, :default => false
      t.integer :taxable_id
      t.string  :taxable_type
      t.integer :created_by_id
      t.decimal :amount, :precision => 8, :scale => 2
      t.boolean :enabled, :default => true
      t.boolean :edited, :default => false
      t.timestamps
    end
    
    Invoice.find(:all).each do |i|
      if i.read_attribute('tax_1_enabled')
        i.taxes.create( :profile_key => 'tax_1', :rate => i.read_attribute('tax_1_rate'), :enabled => true, :name => i.read_attribute('tax_1_name' ))
      end
      if i.read_attribute('tax_2_enabled')
        i.taxes.create( :profile_key => 'tax_2', :rate => i.read_attribute('tax_2_rate'), :enabled => true, :name => i.read_attribute('tax_2_name') )
      end
    end
    
    remove_column :invoices, :tax_1_enabled
    remove_column :invoices, :tax_1_rate
    remove_column :invoices, :tax_1_name
    
    remove_column :invoices, :tax_2_enabled
    remove_column :invoices, :tax_2_rate
    remove_column :invoices, :tax_2_name
    
  end


  def self.down
    add_column :invoices, :tax_1_enabled, :boolean
    add_column :invoices, :tax_1_rate, :decimal, :precision => 8, :scale => 2
    add_column :invoices, :tax_2_enabled, :boolean
    add_column :invoices, :tax_2_rate, :decimal, :precision => 8, :scale => 2
    add_column :invoices, :tax_1_name, :string
    add_column :invoices, :tax_2_name, :string

    Invoice.find(:all).each do |i|
      unless i.tax_1.nil?
        i.write_attribute('tax_1_enabled', i.tax_1.enabled)
        i.write_attribute('tax_1_rate', i.tax_1.rate)
        i.write_attribute('tax_1_name', i.tax_1.name)
      end
      unless i.tax_2.nil?
        i.write_attribute('tax_2_enabled', i.tax_2.enabled)
        i.write_attribute('tax_2_rate', i.tax_2.rate)
        i.write_attribute('tax_2_name', i.tax_2.name)
      end
    end
    
    drop_table :taxes
  end
end
