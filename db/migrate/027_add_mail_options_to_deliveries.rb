class AddMailOptionsToDeliveries < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :mail_options, :text
  end
  def self.down
    remove_column :deliveries, :mail_options
  end
end
