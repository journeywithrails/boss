class RemovePasswordFromSpaccounts < ActiveRecord::Migration
  def self.up
    remove_column :spaccounts, :password
  end

  def self.down
    add_column :spaccounts, :password, :string
  end
end
