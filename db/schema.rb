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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170712192850) do

  create_table "accounts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "identifier"
    t.string "currency"
    t.string "name"
    t.string "nature"
    t.string "balance"
    t.string "iban"
    t.string "cards"
    t.string "swift"
    t.string "client_name"
    t.string "account_name"
    t.string "account_number"
    t.string "available_amount"
    t.string "credit_limit"
    t.string "posted"
    t.string "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "login_id"
    t.index ["login_id"], name: "index_accounts_on_login_id"
  end

  create_table "logins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "username"
    t.string "secret"
    t.string "provider"
    t.string "country"
    t.string "status"
    t.string "next_refresh"
    t.string "error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_logins_on_user_id"
  end

  create_table "transactions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "identifier"
    t.string "category"
    t.string "currency"
    t.string "amount"
    t.string "description"
    t.string "account_balance_snapshot"
    t.string "categorization_confidence"
    t.string "made_on"
    t.string "mode"
    t.boolean "duplicated"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "account_id"
    t.index ["account_id"], name: "index_transactions_on_account_id"
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.string "customer_secret"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "logins"
  add_foreign_key "logins", "users"
  add_foreign_key "transactions", "accounts"
end
