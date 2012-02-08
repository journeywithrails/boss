class CreateLineItems < ActiveRecord::Migration
  def self.up
    create_table :line_items, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.string :name
      t.text :description
      t.integer :invoice_id
      t.integer :position

      t.timestamps 
    end
  end

  def self.down
    drop_table :line_items
  end
end
