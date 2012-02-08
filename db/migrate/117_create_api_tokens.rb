class CreateApiTokens < ActiveRecord::Migration
  def self.up
    create_table :api_tokens do |t|
      t.string :guid
      t.string :language
    end
    add_index :api_tokens, :guid
  end

  def self.down
    drop_table :api_tokens
  end
end
