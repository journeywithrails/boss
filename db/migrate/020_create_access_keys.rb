class CreateAccessKeys < ActiveRecord::Migration
  def self.up
    AccessKey.create_table
  end

  def self.down
    AccessKey.drop_table
  end
end
