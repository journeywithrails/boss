class AddStartStateToBrowsal < ActiveRecord::Migration
  def self.up
    add_column :browsals, :start_status, :string
  end

  def self.down
    remove_column :browsals, :start_status
  end
end
