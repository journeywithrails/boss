class ChangeDefaultForUsersActive < ActiveRecord::Migration
  def self.up
    change_column_default :users, :active, true
  end

  def self.down
    change_column_default :users, :active, nil
  end
end
