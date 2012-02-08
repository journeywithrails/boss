class AddCasColumnsToUsers < ActiveRecord::Migration

  
  def self.up
    add_column :users, :sage_username, :string
    User.reset_column_information
    
    
    User.find(:all).each do |user|
      user.register_sage_user_with_legacy_password!
    end
  end

  def self.down
    remove_column :users, :sage_username
  end
end