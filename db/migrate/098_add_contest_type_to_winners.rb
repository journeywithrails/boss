class AddContestTypeToWinners < ActiveRecord::Migration
  def self.up
    add_column :winners, :contest_type, :string
    Winner.update_all("contest_type = 'BYBS'")
  end

  def self.down
    remove_column :winners, :contest_type
  end
end
