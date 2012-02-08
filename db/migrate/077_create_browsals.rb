class CreateBrowsals < ActiveRecord::Migration
  def self.up
    create_table :browsals do |t|
      t.string :type
      t.string :status
      t.string :title
      t.text :metadata
      t.integer :created_by_id      
      t.timestamps
    end
  end

  def self.down
    drop_table :browsals
  end
end
