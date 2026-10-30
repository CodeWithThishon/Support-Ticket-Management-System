# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_10_29_060656) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ticket_activities", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "user_id", null: false
    t.string "action"
    t.text "details"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ticket_id"], name: "index_ticket_activities_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_activities_on_user_id"
  end

  create_table "ticket_comments", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ticket_id"], name: "index_ticket_comments_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_comments_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "ticket_number", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.bigint "requester_id", null: false
    t.bigint "assignee_id"
    t.string "priority", default: "medium", null: false
    t.string "status", default: "open", null: false
    t.text "resolution_summary"
    t.datetime "resolved_at"
    t.datetime "closed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["requester_id"], name: "index_tickets_on_requester_id"
    t.index ["ticket_number"], name: "index_tickets_on_ticket_number", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "requester", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "reset_digest"
    t.datetime "reset_sent_at"
  end

  add_foreign_key "ticket_activities", "tickets"
  add_foreign_key "ticket_activities", "users"
  add_foreign_key "ticket_comments", "tickets"
  add_foreign_key "ticket_comments", "users"
  add_foreign_key "tickets", "users", column: "assignee_id"
  add_foreign_key "tickets", "users", column: "requester_id"
end
