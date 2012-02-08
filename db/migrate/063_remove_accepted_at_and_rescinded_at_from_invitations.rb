class RemoveAcceptedAtAndRescindedAtFromInvitations < ActiveRecord::Migration
  def self.up
    remove_column :invitations, :accepted_at
    remove_column :invitations, :rescinded_at
  end

  def self.down
    add_column :invitations, :accepted_at, :datetime
    add_column :invitations, :rescinded_at, :datetime
  end
end
