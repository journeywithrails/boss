class AddLanguageToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :language, :string, :limit => 5, :default => "en"
  end

  def self.down
    remove_column :users, :language
  end
end
