class AddInvitationIdToBookkeepingContract < ActiveRecord::Migration
  def self.up
    add_column :bookkeeping_contracts, :invitation_id, :integer
  end

  def self.down
    remove_column :bookkeeping_contracts, :invitation_id
  end
end
