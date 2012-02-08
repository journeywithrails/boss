class ChangeLimitOnDbFilesData < ActiveRecord::Migration
  def self.up
    change_column :db_files, :data, :binary, {:limit => 2147483647}
  end
  
  def self.down
    change_column :db_files, :data, :binary, {:limit => 65535}
  end
end
