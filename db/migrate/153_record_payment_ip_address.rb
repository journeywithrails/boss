class RecordPaymentIpAddress < ActiveRecord::Migration
  def self.up
    add_column :payments, :ip, :string
  end

  def self.down
    remove_column :payments, :ip
  end
end
