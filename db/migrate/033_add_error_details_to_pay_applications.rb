class AddErrorDetailsToPayApplications < ActiveRecord::Migration
  def self.up
    add_column :pay_applications, :error_details, :text
  end

  def self.down
    remove_column :pay_applications, :error_details
  end
end
