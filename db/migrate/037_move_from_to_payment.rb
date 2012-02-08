class MoveFromToPayment < ActiveRecord::Migration
  def self.up
    remove_column :pay_applications, :from
    add_column :payments, :from, :string
  end

  def self.down
    add_column :pay_applications, :from, :string
    remove_column :payments, :from
  end
end
