class AddProcessingLockColumnToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :processing_pid, :integer
  end

  def self.down
    remove_column :payments, :processing_pid
  end
end
