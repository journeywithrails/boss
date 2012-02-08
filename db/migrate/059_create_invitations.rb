class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.integer :invitor_id
      t.integer :invitee_id
      t.string :type
      t.datetime :accepted_at
      t.datetime :rescinded_at
      t.string :status
      t.timestamps
    end
  end

  def self.down
    drop_table :invitations
  end
end
