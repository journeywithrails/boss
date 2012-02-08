class RemoveRogueTablesIfPresent < ActiveRecord::Migration
  def self.up
    execute "drop table if exists `emails`"
    execute "drop table if exists `paypal_gateways`"
    execute "drop table if exists `sage_users`"
  end

  def self.down
  end
end
