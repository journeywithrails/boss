class CreateBookkeeperAndBiller < ActiveRecord::Migration
  def self.up
    create_table :bookkeepers, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    create_table :billers, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    add_column :users, :bookkeeper_id,  :integer
    add_column :users, :biller_id,      :integer
    
  end

  def self.down
    drop_table :bookkeepers
    drop_table :billers
  end
end
