class RemoveCanadaAsDefaultCountry < ActiveRecord::Migration
  def self.up
    change_column :customers, :country, :string
  end

  def self.down
    change_column :customers, :country, :string, :default => 'Canada'    
  end
end
