class AddSendRecipientsToSchedule < ActiveRecord::Migration
  def self.up
    add_column :schedules, :send_recipients, :string
  end

  def self.down
    remove_column :schedules, :send_recipients
  end
end
