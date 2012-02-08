class AddFieldsToCasServiceTicketToMakePrimaryStorageForCasclient < ActiveRecord::Migration
  def self.up
    add_column :cas_service_tickets, :service, :string, :limit => 512
    add_column :cas_service_tickets, :response, :text
    add_column :cas_service_tickets, :renew, :boolean
    add_column :cas_service_tickets, :pgt_iou, :string
    add_column :cas_service_tickets, :cas_ticket_type, :string
  end

  def self.down
    remove_column :cas_service_tickets, :cas_ticket_type
    remove_column :cas_service_tickets, :pgt_iou
    remove_column :cas_service_tickets, :renew
    remove_column :cas_service_tickets, :response
    remove_column :cas_service_tickets, :service
  end
end
