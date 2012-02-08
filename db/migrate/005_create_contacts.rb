class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :customer_id

      t.timestamps 
    end
  end

  def self.down
    drop_table :contacts
  end
end
