class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices , :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.column :created_by_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :customer_id, :integer
    end
  end

  def self.down
    drop_table :invoices
  end
end
