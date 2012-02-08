$IN_MIGRATION = true

require 'application'
require 'payments_controller'
require 'payment'

class AddStatusToPayments < ActiveRecord::Migration

  def self.up
    add_column :payments, :status, :string, :default => 'created'
    
    Payment.update_all("status = 'created'")
  end

  def self.down
    remove_column :payments, :status
  end
end
