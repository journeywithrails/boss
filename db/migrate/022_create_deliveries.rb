class CreateDeliveries < ActiveRecord::Migration
  def self.up
    create_table :deliveries, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.integer     :deliverable_id
      t.string      :deliverable_type
      t.string      :status, :default => 'draft'
      t.string      :recipients
      t.text        :body
      t.timestamps
    end
  end

  def self.down
    drop_table :deliveries
  end
end
