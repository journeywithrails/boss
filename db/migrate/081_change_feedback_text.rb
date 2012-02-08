class ChangeFeedbackText < ActiveRecord::Migration
  def self.up
    change_column :feedbacks, :text_to_send, :text
    change_column :feedbacks, :response_text, :text
  end

  def self.down
    remove_column :feedbacks, :text_to_send
    remove_column :feedbacks, :response_text
    add_column :feedbacks, :text_to_send, :string
    add_column :feedbacks, :response_text, :string
  end
end