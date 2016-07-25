# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160722044100) do

  create_table "activities", id: false, force: :cascade do |t|
    t.integer  "id",               limit: 20, null: false
    t.datetime "period"
    t.string   "prefix"
    t.string   "activityHash"
    t.integer  "result"
    t.string   "team"
    t.string   "kd"
    t.string   "char_activity_id",            null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "activities", ["char_activity_id"], name: "index_activities_on_char_activity_id"
  add_index "activities", ["id"], name: "index_activities_on_id"

  create_table "char_activities", id: false, force: :cascade do |t|
    t.integer  "id",         limit: 20, null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "char_activities", ["id"], name: "index_char_activities_on_id"

end
