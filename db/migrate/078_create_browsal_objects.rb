class CreateBrowsalObjects < ActiveRecord::Migration
  def self.up
    create_table :browsal_objects do |t|
      t.integer :object_id
      t.string :object_type
      t.references :browsal
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :browsal_objects
  end
end
