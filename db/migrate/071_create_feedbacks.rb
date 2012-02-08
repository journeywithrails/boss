class CreateFeedbacks < ActiveRecord::Migration
  def self.up
    create_table :feedbacks do |t|
      t.string :user_name
      t.string :user_email
      t.string :text_to_send
      t.string :response_text
      t.string :response_status
      t.integer :owned_by
      t.datetime :last_reply_mailed_at
      t.timestamps
    end
  end

  def self.down
    drop_table :feedbacks
  end
end
