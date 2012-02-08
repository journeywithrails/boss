class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.integer :user_id
      t.integer :customer_id
      t.integer :pay_type
      t.decimal :amount
      t.date :date
      t.string :description
      t.timestamps 
    end
    
    create_table :pay_applications, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci' do |t|
      t.integer :payment_id
      t.integer :invoice_id
      t.decimal :amount
      t.timestamps 
    end
  end

  def self.down
    drop_table :payments
    drop_table :pay_applications
  end
end
