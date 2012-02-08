class CreateWinners < ActiveRecord::Migration
  def self.up
    create_table :winners do |t|
      t.string :signup_type
      t.date :draw_date
      t.string :prize
      t.string :winner_name
      t.timestamps
    end
  end

  def self.down
    drop_table :winners
  end
end
