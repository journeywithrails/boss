class AddFieldsToCustomer < ActiveRecord::Migration
  def self.up
    add_column :customers, :address1, :string
    add_column :customers, :address2, :string    
    add_column :customers, :city, :string
    add_column :customers, :province_state, :string, :limit => 2
    add_column :customers, :postalcode_zip, :string
    add_column :customers, :country, :string
    add_column :customers, :website, :string
    add_column :customers, :phone, :string    
    add_column :customers, :fax, :string        
  end

  def self.down
    remove_column :customers, :address1
    remove_column :customers, :address2    
    remove_column :customers, :city    
    remove_column :customers, :province_state    
    remove_column :customers, :postalcode_zip    
    remove_column :customers, :country    
    remove_column :customers, :website    
    remove_column :customers, :phone        
    remove_column :customers, :fax            
  end
end
