class AddSubjectToDeliveries < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :subject, :string
  end

  def self.down
    remove_column :deliveries, :subject
  end
end
