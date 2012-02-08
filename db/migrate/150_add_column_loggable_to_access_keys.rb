class AddColumnLoggableToAccessKeys < ActiveRecord::Migration
  def self.up
    add_column :access_keys, :not_tracked, :boolean
  end

  def self.down
    remove_column :access_keys, :not_tracked
  end
end
