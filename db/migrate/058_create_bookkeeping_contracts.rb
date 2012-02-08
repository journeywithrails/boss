class CreateBookkeepingContracts < ActiveRecord::Migration
  def self.up
    create_table :bookkeeping_contracts, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.integer :bookkeeping_client_id
      t.integer :bookkeeper_id
      t.timestamps
    end
  end

  def self.down
    drop_table :bookkeeping_contracts
  end
end
