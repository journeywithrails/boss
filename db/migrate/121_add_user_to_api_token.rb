class AddUserToApiToken < ActiveRecord::Migration
  def self.up
    add_column :api_tokens, :user_id, :integer
  end

  def self.down
    remove_column :api_tokens, :user_id
  end
end
