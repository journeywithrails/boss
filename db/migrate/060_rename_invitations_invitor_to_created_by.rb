class RenameInvitationsInvitorToCreatedBy < ActiveRecord::Migration
  def self.up
    rename_column :invitations, :invitor_id, :created_by_id
  end
  def self.down
    rename_column :invitations, :created_by_id, :invitor_id
  end
end
