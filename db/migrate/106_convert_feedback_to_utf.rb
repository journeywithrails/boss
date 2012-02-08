class ConvertFeedbackToUtf < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE feedbacks CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;"
  end

  def self.down
    #do nothing
  end
end
