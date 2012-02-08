class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.string   :frequency
      t.date     :stop_date
      t.integer  :invoice_id
      t.datetime :deleted_at
      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end
