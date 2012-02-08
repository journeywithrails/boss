class AddColumnTaxedOnToTaxes < ActiveRecord::Migration
  def self.up
    add_column :taxes, :taxed_on, :string
  end

  def self.down
    remove_column :taxes, :taxed_on
  end
end
