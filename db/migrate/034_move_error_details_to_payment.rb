class MoveErrorDetailsToPayment < ActiveRecord::Migration
  def self.up
    add_column :payments, :error_details, :text
    remove_column :pay_applications, :error_details 
  end

  def self.down
    remove_column :payments, :error_details
    add_column :pay_applications, :error_details, :text
  end
end
