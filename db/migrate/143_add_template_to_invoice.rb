class AddTemplateToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :template_name, :string, :limit=>50,  :default => ""

    ActiveRecord::Base.connection.execute("update invoices set template_name='default'")
  end

  def self.down
    remove_column :invoices, :template_name
  end
end
