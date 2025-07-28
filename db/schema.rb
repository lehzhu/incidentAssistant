# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_28_082714) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "flags", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "flag_type"
    t.text "description"
    t.string "reporter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id"], name: "index_flags_on_incident_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0
    t.text "transcript_data"
    t.integer "total_messages", default: 0
    t.integer "processed_messages", default: 0
    t.boolean "replay_completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["replay_completed"], name: "index_incidents_on_replay_completed"
    t.index ["status"], name: "index_incidents_on_status"
  end

  create_table "suggestions", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "status", default: "pending"
    t.text "context"
    t.integer "confidence_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "importance_score", default: 50
    t.integer "trigger_message_sequence"
    t.string "speaker"
    t.boolean "is_action_item", default: false
    t.index ["importance_score"], name: "index_suggestions_on_importance_score"
    t.index ["incident_id", "status"], name: "index_suggestions_on_incident_id_and_status"
    t.index ["incident_id"], name: "index_suggestions_on_incident_id"
    t.index ["is_action_item"], name: "index_suggestions_on_is_action_item"
    t.index ["speaker"], name: "index_suggestions_on_speaker"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "assignee"
    t.text "description"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id"], name: "index_tasks_on_incident_id"
  end

  create_table "transcript_messages", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "speaker", null: false
    t.text "content", null: false
    t.integer "sequence_number", null: false
    t.datetime "simulated_timestamp", precision: nil
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id", "sequence_number"], name: "index_transcript_messages_on_incident_id_and_sequence_number"
    t.index ["incident_id"], name: "index_transcript_messages_on_incident_id"
    t.index ["processed"], name: "index_transcript_messages_on_processed"
  end

  add_foreign_key "flags", "incidents"
  add_foreign_key "suggestions", "incidents"
  add_foreign_key "tasks", "incidents"
  add_foreign_key "transcript_messages", "incidents"
end
