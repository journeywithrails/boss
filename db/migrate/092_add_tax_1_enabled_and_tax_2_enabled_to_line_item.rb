class AddTax1EnabledAndTax2EnabledToLineItem < ActiveRecord::Migration
  def self.up
    add_column :line_items, :tax_1_enabled, :boolean, :default => true
    add_column :line_items, :tax_2_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :line_items, :tax_1_enabled
    remove_column :line_items, :tax_2_enabled
  end
end
