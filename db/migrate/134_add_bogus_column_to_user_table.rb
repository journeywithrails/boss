class AddBogusColumnToUserTable < ActiveRecord::Migration
  def self.up
    add_column :users, :bogus, :boolean, :default => false
  end

  def self.down
    remove_column :users, :bogus
  end
end
