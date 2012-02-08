class FixCreatedByInLogos < ActiveRecord::Migration
  def self.up
    rename_column :logos, :created_by, :created_by_id
  end

  def self.down
    rename_column :logos, :created_by_id, :created_by
  end
end
