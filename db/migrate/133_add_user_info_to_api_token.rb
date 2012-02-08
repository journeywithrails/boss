class AddUserInfoToApiToken < ActiveRecord::Migration
  def self.up
    add_column :api_tokens, :password, :string
  end

  def self.down
    remove_column :api_tokens, :password
  end
end
