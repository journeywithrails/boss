class CreateBounces < ActiveRecord::Migration
  def self.up
    create_table :bounces, :force => true do |t|
      t.integer :user_id
      t.text :body
      
      t.timestamps
    end
  end

  def self.down
    drop_table :bounces
  end
end
