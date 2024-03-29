# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 159) do

  create_table "access_keys", :force => true do |t|
    t.integer  "keyable_id",                      :null => false
    t.string   "keyable_type",                    :null => false
    t.datetime "created_at"
    t.datetime "valid_until"
    t.integer  "uses",         :default => 99999
    t.integer  "used",         :default => 0
    t.string   "key",                             :null => false
    t.boolean  "not_tracked"
  end

  add_index "access_keys", ["key"], :name => "index_access_keys_on_key"

  create_table "activities", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "user_id"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extra"
  end

  create_table "api_tokens", :force => true do |t|
    t.string  "guid"
    t.string  "language"
    t.string  "mode"
    t.integer "user_gateway_id"
    t.boolean "new_gateway"
    t.integer "invoice_id"
    t.integer "delivery_id"
    t.integer "user_id"
    t.string  "password"
    t.string  "simply_username"
  end

  add_index "api_tokens", ["guid"], :name => "index_api_tokens_on_guid"

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "billers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bookkeepers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bookkeeping_contracts", :force => true do |t|
    t.integer  "bookkeeping_client_id"
    t.integer  "bookkeeper_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invitation_id"
  end

  add_index "bookkeeping_contracts", ["bookkeeper_id"], :name => "index_bookkeeping_contracts_on_bookkeeper_id"
  add_index "bookkeeping_contracts", ["bookkeeping_client_id"], :name => "index_bookkeeping_contracts_on_bookkeeping_client_id"
  add_index "bookkeeping_contracts", ["invitation_id"], :name => "index_bookkeeping_contracts_on_invitation_id"

  create_table "bounces", :force => true do |t|
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "delivery_id"
  end

  create_table "browsal_objects", :force => true do |t|
    t.integer  "object_id"
    t.string   "object_type"
    t.integer  "browsal_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "browsals", :force => true do |t|
    t.string   "type"
    t.string   "status"
    t.string   "title"
    t.text     "metadata"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "start_status"
    t.text     "error_messages"
  end

  create_table "cas_service_tickets", :force => true do |t|
    t.string   "st_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "service",         :limit => 512
    t.text     "response"
    t.boolean  "renew"
    t.string   "pgt_iou"
    t.string   "cas_ticket_type"
  end

  create_table "configurable_settings", :force => true do |t|
    t.integer "configurable_id"
    t.string  "configurable_type"
    t.integer "targetable_id"
    t.string  "targetable_type"
    t.string  "name",              :null => false
    t.string  "value_type"
    t.text    "value"
  end

  add_index "configurable_settings", ["name"], :name => "index_configurable_settings_on_name"
  add_index "configurable_settings", ["configurable_id"], :name => "index_configurable_settings_on_configurable_id"

  create_table "contacts", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
  end

  add_index "contacts", ["customer_id"], :name => "index_contacts_on_customer_id"

  create_table "customers", :force => true do |t|
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "default_contact_id"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "province_state"
    t.string   "postalcode_zip"
    t.string   "country",                         :default => "Canada"
    t.string   "website"
    t.string   "phone"
    t.string   "fax"
    t.string   "simply_guid"
    t.string   "language",           :limit => 5, :default => "en"
  end

  add_index "customers", ["created_by_id"], :name => "index_customers_on_created_by_id"
  add_index "customers", ["default_contact_id"], :name => "index_customers_on_default_contact_id"

  create_table "db_files", :force => true do |t|
    t.binary "data"
  end

  create_table "deliveries", :force => true do |t|
    t.integer  "deliverable_id"
    t.string   "deliverable_type"
    t.string   "status",           :default => "draft"
    t.string   "recipients"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mail_name"
    t.integer  "created_by_id"
    t.string   "message_id"
    t.text     "mail_options"
    t.string   "subject"
    t.text     "error_details"
    t.integer  "access_key_id"
  end

  add_index "deliveries", ["created_by_id"], :name => "index_deliveries_on_created_by_id"
  add_index "deliveries", ["deliverable_id"], :name => "index_deliveries_on_deliverable_id"

  create_table "feedbacks", :force => true do |t|
    t.string   "user_name"
    t.string   "user_email"
    t.text     "text_to_send"
    t.text     "response_text"
    t.string   "response_status"
    t.integer  "owned_by"
    t.datetime "last_reply_mailed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "created_by_id"
    t.integer  "invitee_id"
    t.string   "type"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invitations", ["created_by_id"], :name => "index_invitations_on_created_by_id"
  add_index "invitations", ["invitee_id"], :name => "index_invitations_on_invitee_id"

  create_table "invoice_files", :force => true do |t|
    t.integer "simply_accounting_invoice_id"
    t.string  "content_type"
    t.string  "filename"
    t.string  "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.integer "db_file_id"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.text     "description"
    t.integer  "contact_id"
    t.integer  "unique_number"
    t.date     "date"
    t.string   "reference"
    t.string   "unique_name"
    t.string   "status",                                                           :default => "draft"
    t.decimal  "discount_amount",                    :precision => 8, :scale => 2
    t.decimal  "total_amount",                       :precision => 8, :scale => 2, :default => 0.0
    t.string   "discount_type"
    t.decimal  "discount_value",                     :precision => 8, :scale => 2
    t.datetime "deleted_at"
    t.boolean  "discount_before_tax"
    t.date     "due_date"
    t.string   "currency"
    t.datetime "calculated_at"
    t.decimal  "tax_1_amount",                       :precision => 8, :scale => 2, :default => 0.0
    t.decimal  "tax_2_amount",                       :precision => 8, :scale => 2, :default => 0.0
    t.decimal  "subtotal_amount",                    :precision => 8, :scale => 2, :default => 0.0
    t.string   "using_gateways"
    t.string   "type"
    t.decimal  "simply_amount_owing",                :precision => 8, :scale => 2, :default => 0.0
    t.string   "simply_guid"
    t.integer  "superceded_by_id"
    t.decimal  "paid_amount",                        :precision => 8, :scale => 2, :default => 0.0
    t.decimal  "owing_amount",                       :precision => 8, :scale => 2, :default => 0.0
    t.string   "payment_types"
    t.boolean  "changed_printed",                                                  :default => false
    t.string   "template_name",        :limit => 50,                               :default => ""
    t.integer  "quote_unique_number"
    t.integer  "recurring_invoice_id"
  end

  add_index "invoices", ["created_by_id"], :name => "index_invoices_on_created_by_id"
  add_index "invoices", ["contact_id"], :name => "index_invoices_on_contact_id"
  add_index "invoices", ["customer_id"], :name => "index_invoices_on_customer_id"

  create_table "line_items", :force => true do |t|
    t.string   "unit"
    t.text     "description"
    t.integer  "invoice_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "quantity",      :precision => 8, :scale => 2
    t.decimal  "price",         :precision => 8, :scale => 2
    t.boolean  "tax_1_enabled",                               :default => true
    t.boolean  "tax_2_enabled",                               :default => true
  end

  add_index "line_items", ["invoice_id"], :name => "index_line_items_on_invoice_id"

  create_table "logos", :force => true do |t|
    t.integer  "created_by_id"
    t.integer  "parent_id"
    t.string   "name"
    t.string   "content_type"
    t.string   "thumbnail"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename"
  end

  add_index "logos", ["created_by_id"], :name => "index_logos_on_created_by_id"

  create_table "pay_applications", :force => true do |t|
    t.integer  "payment_id"
    t.integer  "invoice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.decimal  "amount",        :precision => 8, :scale => 2
  end

  add_index "pay_applications", ["created_by_id"], :name => "index_pay_applications_on_created_by_id"
  add_index "pay_applications", ["invoice_id"], :name => "index_pay_applications_on_invoice_id"
  add_index "pay_applications", ["payment_id"], :name => "index_pay_applications_on_payment_id"

  create_table "payments", :force => true do |t|
    t.integer  "customer_id"
    t.date     "date"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.decimal  "amount",             :precision => 8, :scale => 2
    t.string   "status",                                           :default => "created"
    t.string   "pay_type"
    t.text     "error_details"
    t.string   "from"
    t.string   "gateway_token"
    t.datetime "gateway_token_date"
    t.string   "processing_pid"
    t.string   "payment_type"
    t.string   "ip"
  end

  add_index "payments", ["created_by_id"], :name => "index_payments_on_created_by_id"
  add_index "payments", ["customer_id"], :name => "index_payments_on_customer_id"

  create_table "referrals", :force => true do |t|
    t.string   "referring_email"
    t.string   "referring_name"
    t.string   "referring_type"
    t.string   "friend_email"
    t.string   "friend_name"
    t.string   "referral_code"
    t.datetime "sent_at"
    t.integer  "user_id"
    t.datetime "accepted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"
  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"

  create_table "schedules", :force => true do |t|
    t.string   "frequency"
    t.date     "stop_date"
    t.integer  "invoice_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "send_recipients"
  end

  create_table "simple_captcha_data", :force => true do |t|
    t.string   "key",        :limit => 40
    t.string   "value",      :limit => 6
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.string   "sluggable_type"
    t.integer  "sluggable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "slugs", ["name", "sluggable_type"], :name => "index_slugs_on_name_and_sluggable_type", :unique => true
  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

  create_table "spaccounts", :force => true do |t|
    t.string   "spaccount_name"
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
    t.integer  "status",         :default => 0
    t.string   "comment"
    t.integer  "user_id"
  end

  create_table "spsubscriptions", :force => true do |t|
    t.integer  "spaccount_id"
    t.string   "service_code"
    t.integer  "qty"
    t.integer  "status"
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_id"
  end

  create_table "taxes", :force => true do |t|
    t.integer  "parent_id"
    t.decimal  "rate",          :precision => 8, :scale => 2
    t.string   "profile_key"
    t.string   "name"
    t.boolean  "included",                                    :default => false
    t.integer  "taxable_id"
    t.string   "taxable_type"
    t.integer  "created_by_id"
    t.decimal  "amount",        :precision => 8, :scale => 2, :default => 0.0
    t.boolean  "enabled",                                     :default => true
    t.boolean  "edited",                                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "taxed_on"
  end

  create_table "user_gateways", :force => true do |t|
    t.string  "type"
    t.integer "user_id"
    t.string  "gateway_name"
    t.string  "merchant_id"
    t.string  "merchant_key"
    t.string  "login"
    t.text    "password"
    t.string  "email"
    t.boolean "active",       :default => true
    t.string  "currency"
  end

  add_index "user_gateways", ["user_id"], :name => "index_user_gateways_on_user_id"
  add_index "user_gateways", ["user_id", "gateway_name"], :name => "index_user_gateways_on_user_id_and_gateway_name"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.text     "searches"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.integer  "bookkeeper_id"
    t.integer  "biller_id"
    t.string   "signup_type"
    t.string   "heard_from"
    t.string   "language",                  :limit => 5,  :default => "en"
    t.boolean  "active",                                  :default => true
    t.boolean  "bogus",                                   :default => false
    t.string   "sage_username"
  end

  add_index "users", ["bookkeeper_id"], :name => "index_users_on_bookkeeper_id"
  add_index "users", ["biller_id"], :name => "index_users_on_biller_id"

  create_table "winners", :force => true do |t|
    t.string   "signup_type"
    t.date     "draw_date"
    t.string   "prize"
    t.string   "winner_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contest_type"
  end

end
