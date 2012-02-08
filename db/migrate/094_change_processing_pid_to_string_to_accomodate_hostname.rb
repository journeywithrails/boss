class ChangeProcessingPidToStringToAccomodateHostname < ActiveRecord::Migration
  def self.up
    remove_column :payments, :processing_pid
    add_column :payments, :processing_pid, :string
  end

  def self.down
    remove_column :payments, :processing_pid
    add_column :payments, :processing_pid, :integer
  end
end
