class ChangeCustomerProvinceStateLength < ActiveRecord::Migration
  def self.up
    change_column :customers, :province_state, :string
  end

  def self.down
    change_column :customers, :province_state, :string, :limit => 2
  end
    
end
