class AddInvoiceToApiToken < ActiveRecord::Migration
  def self.up
    add_column :api_tokens, :invoice_id, :integer
  end

  def self.down
    remove_column :api_tokens, :invoice_id
  end
end
