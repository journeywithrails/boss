class AddGuidToBrowsal < ActiveRecord::Migration
  def self.up
    add_column :browsals, :guid, :string
  end

  def self.down
    remove_column :browsals, :guid
  end
end
