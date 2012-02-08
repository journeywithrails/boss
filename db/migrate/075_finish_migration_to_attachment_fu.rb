class FinishMigrationToAttachmentFu < ActiveRecord::Migration
  def self.up
    remove_column :logos, :logo
  end

  def self.down
    add_column :logos, :logo, :string
  end
end
