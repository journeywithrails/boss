class CreateLogos < ActiveRecord::Migration
  def self.up
    create_table :logos, :options => 'ENGINE=INNODB DEFAULT CHARSET=UTF8 COLLATE=utf8_general_ci', :force => true do |t|
      t.column :created_by, :integer
      t.column :parent_id,  :integer
      t.column :name, :string
      t.column :content_type, :string
      t.column :filename, :string    
      t.column :thumbnail, :string 
      t.column :size, :integer
      t.column :width, :integer
      t.column :height, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :logos
  end
end
