class AddSearchesColumnToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :searches, :text
  end

  def self.down
    remove_column :users, :searches
  end
end
