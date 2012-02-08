class StoreInitialUsernameInApiToken < ActiveRecord::Migration
  def self.up
    unless ApiToken.column_names.include? "simply_username"
      add_column :api_tokens, :simply_username, :string
    end
  end

  def self.down
    remove_column :api_tokens, :simply_username
  end
end
