class ChangeCountryToHaveDefaultCanada < ActiveRecord::Migration
  def self.up
    change_column :customers, :country, :string, :default => 'Canada'
  end

  def self.down
    change_column :customers, :country, :string
  end
end
