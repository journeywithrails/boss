class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :invoices, :created_by_id
    add_index :contacts, :customer_id
    add_index :configurable_settings, :configurable_id
    add_index :customers, :created_by_id
    add_index :invitations, :created_by_id  
    add_index :line_items, :invoice_id
    add_index :logos, :created_by_id
    add_index :pay_applications, :created_by_id
    add_index :payments, :created_by_id
    add_index :users, :login
  end

  def self.down
    remove_index :invoices, :created_by_id
    remove_index :contacts, :customer_id
    remove_index :configurable_settings, :configurable_id    
    remove_index :customers, :created_by_id
    remove_index :invitations, :created_by_id  
    remove_index :line_items, :invoice_id
    remove_index :logos, :created_by_id
    remove_index :pay_applications, :created_by_id
    remove_index :payments, :created_by_id
    remove_index :users, :login    
  end
end
