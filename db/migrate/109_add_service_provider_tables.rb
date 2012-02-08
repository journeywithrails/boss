class AddServiceProviderTables < ActiveRecord::Migration
  def self.up
    create_table "slugs", :force => true do |t|
      t.string   "name"
      t.string   "sluggable_type"
      t.integer  "sluggable_id",   :limit => 11
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "slugs", ["name", "sluggable_type"], :name => "index_slugs_on_name_and_sluggable_type", :unique => true
    add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

    create_table "spaccounts", :force => true do |t|
      t.string   "spaccount_name"
      t.string   "password"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "address"
      t.string   "city"
      t.string   "state_prov"
      t.string   "zip_postal"
      t.string   "email"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "company"
      t.string   "country"
      t.string   "phone"
      t.string   "fax"
      t.string   "transaction_id"
      t.integer  "status",         :limit => 11, :default => 0
      t.string   "comment"
      t.integer  "user_id"
    
    end

    create_table "spsubscriptions", :force => true do |t|
      t.integer  "spaccount_id",   :limit => 11
      t.string   "service_code"
      t.integer  "qty",            :limit => 11
      t.integer  "status",         :limit => 11
      t.string   "comment"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "transaction_id"
    end
  end

  def self.down
    drop_table :slugs
    drop_table :spaccounts
    drop_table :spsubscriptions
  end
end
