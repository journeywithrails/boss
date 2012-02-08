class CreateReferrals < ActiveRecord::Migration
  def self.up
    create_table :referrals, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.string :referring_email
      t.string :referring_name
      t.string :referring_type
      t.string :friend_email
      t.string :friend_name
      t.string :referral_code
      t.datetime :sent_at
      t.integer :user_id
      t.datetime :accepted_at
      t.timestamps
    end
  end

  def self.down
    drop_table :referrals
  end
end