# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110502065915) do

  create_table "accountlogs", :force => true do |t|
    t.integer  "user_id"
    t.integer  "operator_id"
    t.integer  "trade_id"
    t.string   "description"
    t.float    "amount"
    t.string   "log_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.string   "article_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "issues", :force => true do |t|
    t.string   "title"
    t.string   "content"
    t.string   "description"
    t.string   "memo"
    t.string   "status"
    t.string   "itype"
    t.integer  "target_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "dealer_id"
  end

  create_table "message_boxes", :force => true do |t|
    t.integer  "message_id"
    t.integer  "user_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.string   "title"
    t.string   "content"
    t.string   "msg_type"
    t.integer  "priority"
    t.string   "status"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notices", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "participants", :force => true do |t|
    t.string   "name"
    t.string   "part_id"
    t.string   "part_type"
    t.string   "role_type"
    t.string   "url"
    t.string   "status"
    t.integer  "score"
    t.float    "life"
    t.boolean  "active"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "penalties", :force => true do |t|
    t.float    "point"
    t.float    "money"
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "issue_id"
    t.integer  "user_id"
  end

  create_table "rails_admin_histories", :force => true do |t|
    t.string   "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_histories_on_item_and_table_and_month_and_year"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", :force => true do |t|
    t.float    "point_ratio",         :default => 1.0
    t.float    "score_ratio",         :default => 1.0
    t.float    "init_required_point", :default => 0.0
    t.float    "init_gift_point",     :default => 2.0
    t.integer  "class1",              :default => 100
    t.integer  "class2",              :default => 200
    t.integer  "class3",              :default => 500
    t.integer  "class4",              :default => 800
    t.integer  "class5",              :default => 1000
    t.float    "task_punish",         :default => 1.0
    t.float    "charge_punish",       :default => 1.0
    t.float    "report_award",        :default => 1.0
    t.float    "report_punish",       :default => 1.0
    t.float    "custom_judge",        :default => 0.2
    t.integer  "real_level",          :default => 5
    t.float    "transport_price",     :default => 0.2
    t.integer  "times_limit",         :default => 3
    t.integer  "running_task",        :default => 10
    t.integer  "total_task",          :default => 100
    t.integer  "total_user",          :default => 220
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasklogs", :force => true do |t|
    t.integer  "task_id"
    t.integer  "user_id"
    t.integer  "worker_id"
    t.float    "price"
    t.float    "point"
    t.string   "status"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.string   "title"
    t.string   "task_type"
    t.string   "description"
    t.string   "shop"
    t.string   "link"
    t.float    "price"
    t.float    "point"
    t.string   "status"
    t.string   "tran_type"
    t.string   "tran_id"
    t.datetime "published_time"
    t.datetime "takeover_time"
    t.datetime "pay_time"
    t.datetime "finished_time"
    t.datetime "confirmed_time"
    t.integer  "worker_level",         :default => 0
    t.integer  "task_day",             :default => 1
    t.boolean  "extra_word",           :default => false
    t.integer  "avoid_day",            :default => 7
    t.boolean  "custom_judge",         :default => false
    t.string   "custom_judge_content"
    t.integer  "real_level",           :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "worker_id"
    t.integer  "supervisor_id"
    t.integer  "participant_id"
    t.integer  "transport_id"
  end

  create_table "trades", :force => true do |t|
    t.string   "price"
    t.string   "status"
    t.string   "description"
    t.string   "trade_type"
    t.string   "transaction_id"
    t.integer  "user_id"
    t.integer  "to_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transports", :force => true do |t|
    t.string   "tran_type"
    t.string   "tran_id"
    t.string   "status"
    t.string   "from"
    t.string   "to"
    t.string   "source"
    t.boolean  "real_tran",  :default => false
    t.datetime "tran_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_transports", :force => true do |t|
    t.integer  "user_id"
    t.integer  "transport_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",  :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",  :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "im"
    t.string   "im_q"
    t.string   "bank_name"
    t.integer  "bank_account"
    t.string   "shop_taobao"
    t.string   "shop_taobao_url"
    t.string   "shop_paipai"
    t.string   "shop_paipai_url"
    t.string   "shop_youa"
    t.string   "shop_youa_url"
    t.string   "mobile"
    t.string   "person_id"
    t.float    "account_credit",                      :default => 0.0
    t.float    "account_money",                       :default => 0.0
    t.float    "payment_money",                       :default => 0.0
    t.float    "score",                               :default => 0.0
    t.string   "status"
    t.string   "operate_password"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

end
