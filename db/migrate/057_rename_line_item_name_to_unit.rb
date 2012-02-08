class RenameLineItemNameToUnit < ActiveRecord::Migration
  def self.up
    rename_column :line_items, :name, :unit
  end

  def self.down
    rename_column :line_items, :unit, :name
  end
end
