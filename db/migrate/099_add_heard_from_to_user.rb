class AddHeardFromToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :heard_from, :string
  end

  def self.down
    remove_column :users, :heard_from
  end
end
