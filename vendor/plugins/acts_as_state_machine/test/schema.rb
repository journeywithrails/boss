ActiveRecord::Schema.define(:version => 1) do
  create_table :conversations do |t|
    t.column :state_machine, :string
    t.column :subject,       :string
    t.column :closed,        :boolean
  end
  
  create_table :strict_conversations do |t|
    t.column :state_machine, :string
    t.column :subject,       :string
    t.column :closed,        :boolean
  end
  
  create_table :people do |t|
    t.column :name, :string
  end
end
