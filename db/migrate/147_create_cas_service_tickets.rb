class CreateCasServiceTickets < ActiveRecord::Migration
  def self.up
    create_table :cas_service_tickets, :force => true do |t|
      t.column :st_id, :string
      t.column :user_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :cas_service_tickets
  end
end
