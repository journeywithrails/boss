class AddFromToPayApplicationsForReal < ActiveRecord::Migration
  def self.up
    add_column :pay_applications, :from, :string
  end

  def self.down
    remove_column :pay_applications, :from
  end
end
