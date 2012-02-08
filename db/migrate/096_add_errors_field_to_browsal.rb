class AddErrorsFieldToBrowsal < ActiveRecord::Migration
  def self.up
    add_column :browsals, :error_messages, :text
  end

  def self.down
    remove_column :browsals, :error_messages
  end
end
