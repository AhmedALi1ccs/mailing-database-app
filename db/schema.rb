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

ActiveRecord::Schema[7.1].define(version: 2025_05_01_161935) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "mailed", id: :serial, force: :cascade do |t|
    t.string "full_name"
    t.string "first_name"
    t.string "last_name"
    t.string "mailing_address", null: false
    t.string "mailing_city", null: false
    t.string "mailing_state", null: false
    t.string "mailing_zip", null: false
    t.string "property_address", null: false
    t.string "property_city", null: false
    t.string "property_state", null: false
    t.string "property_zip", null: false
    t.decimal "checkval", precision: 15, scale: 2
    t.string "mail_month"
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.index ["full_name"], name: "idx_mailed_full_name"
    t.index ["last_name"], name: "idx_mailed_last_name"
    t.index ["mailing_address"], name: "idx_mailed_mailing_address"
    t.index ["mailing_zip"], name: "idx_mailed_mailing_zip"
    t.index ["property_address"], name: "idx_mailed_property_address"
    t.index ["property_zip"], name: "idx_mailed_property_zip"
  end

  create_table "previouscampaigns", id: :serial, force: :cascade do |t|
    t.text "mailing_address", null: false
    t.string "campaign", limit: 20, null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "Group", limit: 1

    t.unique_constraint ["mailing_address", "campaign", "Group"], name: "previouscampaigns_address_campaign_group_key"
  end

  create_table "probate", id: :serial, force: :cascade do |t|
    t.text "parcel_number"
    t.text "full name"
    t.text "First Name"
    t.text "Last Name"
    t.text "Property address"
    t.text "Property city"
    t.text "Property state"
    t.text "Property zip"
    t.text "Mailing address"
    t.text "Mailing city"
    t.text "Mailing state"
    t.text "Mailing zip"
    t.index ["Property address"], name: "idx_probate_property_address"
    t.index ["parcel_number"], name: "idx_probate_parcel_number"
  end

  create_table "properties", id: :serial, force: :cascade do |t|
    t.string "parcel_number", limit: 50
    t.text "full name"
    t.text "First Name"
    t.text "Last Name"
    t.text "Property address"
    t.string "Property city", limit: 100
    t.string "Property state", limit: 2
    t.string "Property zip", limit: 10
    t.string "county", limit: 50
    t.text "Mailing address"
    t.string "Mailing city", limit: 100
    t.string "Mailing state", limit: 2
    t.string "Mailing zip", limit: 10
    t.text "Estimated Value"
    t.date "Sale Date"
    t.decimal "Sale Price"
    t.string "Group", limit: 1
  end

end
