class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.integer :invoice_id
      t.integer :user_id
      t.string :body

      t.timestamps
    end
  end

  def self.down
    drop_table :activities
  end
end
