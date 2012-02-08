class AddDbFiles < ActiveRecord::Migration
  def self.up
    add_column :invoice_files, :db_file_id, :integer
    create_table :db_files do |t|
      t.column :data, :binary
    end
  end

  def self.down
    drop_table :db_files
    remove_column :invoice_files, :db_file_id
  end
end
