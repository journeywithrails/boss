class AddForeignKeyIndexes < ActiveRecord::Migration
  def self.up
    add_index :bookkeeping_contracts, :bookkeeper_id    
    add_index :bookkeeping_contracts, :bookkeeping_client_id
    add_index :bookkeeping_contracts, :invitation_id        
    add_index :customers, :default_contact_id
    add_index :deliveries, :created_by_id
    add_index :deliveries, :deliverable_id    
    add_index :invitations, :invitee_id
    add_index :invoices, :contact_id
    add_index :invoices, :customer_id    
    add_index :pay_applications, :invoice_id    
    add_index :pay_applications, :payment_id
    add_index :payments, :customer_id
    add_index :roles, :authorizable_id
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id 
    add_index :users, :bookkeeper_id 
    add_index :users, :biller_id     
  end

  def self.down
    remove_index :bookkeeping_contracts, :bookkeeper_id    
    remove_index :bookkeeping_contracts, :bookkeeping_client_id
    remove_index :bookkeeping_contracts, :invitation_id        
    remove_index :customers, :default_contact_id
    remove_index :deliveries, :created_by_id
    remove_index :deliveries, :deliverable_id    
    remove_index :invitations, :invitee_id
    remove_index :invoices, :contact_id
    remove_index :invoices, :customer_id    
    remove_index :pay_applications, :invoice_id    
    remove_index :pay_applications, :payment_id
    remove_index :payments, :customer_id
    remove_index :roles, :authorizable_id
    remove_index :roles_users, :user_id
    remove_index :roles_users, :role_id 
    remove_index :users, :bookkeeper_id 
    remove_index :users, :biller_id     
  end
end
