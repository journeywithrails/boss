class RefactorPaymentTypeToString < ActiveRecord::Migration
  def self.up
    
    remove_column :payments, :pay_type
    add_column :payments, :pay_type, :string
    Payment.update_all("pay_type = 'cash'")
    
    drop_table :payment_types
  end

  def self.down
    create_table :payment_types, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.string :name
      t.string :description
    end
    
    PaymentType.create(:name => 'cheque', :description => 'Payments made with cheque')
    PaymentType.create(:name => 'cash', :description => 'Payments made with cash')
    PaymentType.create(:name => 'credit card', :description => 'Payments made by credit card')
    PaymentType.create(:name => 'PayPal', :description => 'Payments made through PayPal')
  end
end
