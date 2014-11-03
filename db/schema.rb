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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131204104019) do

  create_table "activities", :force => true do |t|
    t.integer  "entity_id"
    t.text     "entity_type"
    t.integer  "event_id"
    t.integer  "from_id"
    t.integer  "to_id"
    t.text     "note"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "events", :force => true do |t|
    t.text     "event_type"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "name"
  end

  create_table "job_metadata", :force => true do |t|
    t.integer  "job_id"
    t.text     "key"
    t.text     "value"
    t.text     "metadata_type"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "jobs", :force => true do |t|
    t.text     "name"
    t.integer  "user_id"
    t.integer  "status_id"
    t.integer  "catalog_id"
    t.integer  "project_id"
    t.text     "title"
    t.text     "author"
    t.text     "barcode"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.text     "xml"
    t.text     "mods"
    t.boolean  "quarantined",        :default => false
    t.text     "comment"
    t.text     "object_info"
    t.integer  "priority",           :default => 0
    t.integer  "copyright"
    t.integer  "guessed_page_count", :default => 0
    t.integer  "page_count"
    t.integer  "source_id"
    t.text     "search_title"
  end

  create_table "projects", :force => true do |t|
    t.text     "name"
    t.integer  "user_id"
    t.text     "note"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "copyright"
  end

  create_table "roles", :force => true do |t|
    t.text     "name"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sources", :force => true do |t|
    t.text     "classname"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "statuses", :force => true do |t|
    t.text     "name"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "return_to_previous", :default => false
    t.integer  "end_id"
    t.integer  "selection_order"
    t.boolean  "show",               :default => false
    t.text     "progress_state",     :default => "started"
  end

  create_table "users", :force => true do |t|
    t.integer  "role_id"
    t.text     "email"
    t.text     "username"
    t.text     "password"
    t.text     "name"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "deleted_by"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "mailalerts", :default => false
  end

end
