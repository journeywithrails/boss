class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.integer :user_id
      t.string :name
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :country
      t.string :phone
      t.string :fax

      t.timestamps 
    end
  end

  def self.down
    drop_table :profiles
  end
end
