class AddLanguageToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :language, :string, :limit => 5, :default => "en"
  end

  def self.down
    remove_column :customers, :language
  end
end
