class AddFieldsToApiToken < ActiveRecord::Migration
  def self.up
    add_column 'api_tokens', :mode, :string
    add_column 'api_tokens', :user_gateway_id, :integer
    add_column 'api_tokens', :new_gateway, :boolean
  end

  def self.down
    remove_column 'api_tokens', :mode
    remove_column 'api_tokens', :user_gateway_id
    remove_column 'api_tokens', :new_gateway
  end
end
