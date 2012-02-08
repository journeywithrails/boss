class AddDefaultContactToCustomer < ActiveRecord::Migration
  def self.up
    add_column :customers, :default_contact_id, :integer
  end

  def self.down
    remove_column :customers, :default_contact_id
  end
end
