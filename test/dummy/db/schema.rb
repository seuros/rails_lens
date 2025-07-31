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

ActiveRecord::Schema[8.0].define(version: 2025_07_31_083442) do
  create_schema "audit"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "alerts", force: :cascade do |t|
    t.string "severity"
    t.string "alert_type"
    t.text "description"
    t.boolean "resolved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "announcements", force: :cascade do |t|
    t.text "body"
    t.string "audience"
    t.datetime "scheduled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.integer "user_id", null: false
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "crew_members", force: :cascade do |t|
    t.string "name"
    t.string "rank"
    t.string "species"
    t.string "birth_planet"
    t.text "service_record"
    t.boolean "active"
    t.datetime "joined_starfleet_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", limit: 20
    t.string "specialization"
  end

  create_table "crew_mission_stats_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "diet_relationships", force: :cascade do |t|
    t.bigint "predator_id", null: false
    t.bigint "prey_id", null: false
    t.string "relationship_type"
    t.integer "intensity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "evidence_type", limit: 20
    t.index ["predator_id"], name: "index_diet_relationships_on_predator_id"
    t.index ["prey_id"], name: "index_diet_relationships_on_prey_id"
  end

  create_table "dinosaurs", force: :cascade do |t|
    t.string "name"
    t.string "species"
    t.string "period"
    t.string "diet"
    t.decimal "length"
    t.decimal "weight"
    t.date "discovered_at"
    t.date "extinction_date"
    t.integer "fossil_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entries", force: :cascade do |t|
    t.string "title"
    t.boolean "published"
    t.string "entryable_type"
    t.bigint "entryable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "excavation_sites", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.string "coordinates"
    t.decimal "depth"
    t.string "soil_type"
    t.date "discovered_at"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rock_formation", limit: 20
    t.string "climate_ancient", limit: 20
  end

  create_table "families", force: :cascade do |t|
    t.string "name"
    t.string "classification"
    t.string "taxonomic_rank"
    t.integer "parent_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "family_hierarchies", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.integer "generations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "forgotten_wars", force: :cascade do |t|
    t.string "name"
    t.integer "start_year"
    t.integer "end_year"
    t.string "region"
    t.string "war_type"
    t.string "outcome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fossil_discoveries", force: :cascade do |t|
    t.bigint "dinosaur_id", null: false
    t.bigint "excavation_site_id", null: false
    t.date "discovered_at"
    t.string "condition"
    t.decimal "completeness"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preservation_quality", limit: 20
    t.string "fossil_type", limit: 20
    t.index ["dinosaur_id"], name: "index_fossil_discoveries_on_dinosaur_id"
    t.index ["excavation_site_id"], name: "index_fossil_discoveries_on_excavation_site_id"
  end

  create_table "home_planet_hierarchies", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.integer "generations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "home_planets", force: :cascade do |t|
    t.string "name"
    t.string "galaxy"
    t.st_geometry "coordinates", srid: 4326
    t.decimal "habitability_score", precision: 5, scale: 2
    t.string "climate_type"
    t.bigint "population"
    t.date "established_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "classification", limit: 20
    t.string "hierarchy_type", limit: 20
    t.index ["coordinates"], name: "index_home_planets_on_coordinates", using: :gist
  end

  create_table "maintenance_records", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.string "service_type"
    t.decimal "cost"
    t.date "service_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_maintenance_records_on_vehicle_id"
  end

  create_table "manufacturer_hierarchies", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.integer "generations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "manufacturers", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.integer "founded_year"
    t.text "headquarters"
    t.string "website"
    t.decimal "annual_revenue"
    t.boolean "active"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", limit: 20
    t.string "company_type", limit: 20
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.string "recipient"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mission_waypoints", force: :cascade do |t|
    t.bigint "mission_id", null: false
    t.integer "sequence"
    t.string "coordinates"
    t.datetime "eta"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "waypoint_type", limit: 20
    t.string "status", limit: 20
    t.index ["mission_id"], name: "index_mission_waypoints_on_mission_id"
  end

  create_table "missions", force: :cascade do |t|
    t.string "name"
    t.text "objective"
    t.string "status"
    t.integer "priority"
    t.date "start_date"
    t.date "end_date"
    t.interval "estimated_duration"
    t.string "classification_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "classification", limit: 20
  end

  create_table "order_line_items", primary_key: ["order_id", "line_number"], force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "line_number", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2
    t.string "product_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "line_number"], name: "index_order_line_items_on_order_id_and_line_number", unique: true
    t.index ["order_id"], name: "index_order_line_items_on_order_id"
  end

  create_table "owners", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.date "date_of_birth"
    t.string "license_number"
    t.integer "credit_score"
    t.decimal "net_worth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "license_class", limit: 20
  end

  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.integer "user_id", null: false
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_posts_on_published"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "product_metrics", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.integer "views", default: 0, null: false
    t.integer "purchases", default: 0, null: false
    t.decimal "revenue", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "conversion_rate", type: :decimal, as: "\nCASE\n    WHEN (views > 0) THEN (((purchases)::numeric / (views)::numeric) * (100)::numeric)\n    ELSE (0)::numeric\nEND", stored: true
    t.virtual "average_order_value", type: :decimal, as: "\nCASE\n    WHEN (purchases > 0) THEN (revenue / (purchases)::numeric)\n    ELSE (0)::numeric\nEND", stored: true
    t.index ["conversion_rate"], name: "index_product_metrics_on_conversion_rate"
    t.index ["product_id"], name: "index_product_metrics_on_product_id"
    t.check_constraint "purchases >= 0", name: "check_positive_purchases"
    t.check_constraint "revenue >= 0::numeric", name: "check_positive_revenue"
    t.check_constraint "views >= 0", name: "check_positive_views"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "category"
    t.boolean "active", default: true, null: false
    t.string "sku"
    t.integer "stock_quantity", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category"], name: "index_products_on_category"
    t.index ["name"], name: "index_products_on_name"
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "spaceship_crew_members", force: :cascade do |t|
    t.bigint "spaceship_id", null: false
    t.bigint "crew_member_id", null: false
    t.string "position"
    t.datetime "assigned_at"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_member_id"], name: "index_spaceship_crew_members_on_crew_member_id"
    t.index ["spaceship_id"], name: "index_spaceship_crew_members_on_spaceship_id"
  end

  create_table "spaceships", force: :cascade do |t|
    t.string "name"
    t.string "class_type"
    t.boolean "warp_capability"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.integer "cargo_capacity"
    t.string "cargo_type"
    t.string "battle_status"
  end

  create_table "spatial_coordinates", force: :cascade do |t|
    t.st_geometry "location", srid: 4326
    t.st_point "coordinates", srid: 4326
    t.jsonb "sensor_data"
    t.json "metadata"
    t.inet "ip_address"
    t.uuid "tracking_id"
    t.float "altitude"
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.datetime "recorded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "spaceship_id", null: false
    t.index ["coordinates"], name: "index_spatial_coordinates_on_coordinates", using: :gist
    t.index ["location"], name: "index_spatial_coordinates_on_location", using: :gist
    t.index ["spaceship_id"], name: "index_spatial_coordinates_on_spaceship_id"
  end

  create_table "species", force: :cascade do |t|
    t.string "name"
    t.bigint "family_id", null: false
    t.integer "average_lifespan"
    t.text "habitat"
    t.integer "danger_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locomotion", limit: 20
    t.index ["family_id"], name: "index_species_on_family_id"
  end

  create_table "starfleet_battle_cruisers", force: :cascade do |t|
    t.string "name"
    t.string "registry"
    t.string "captain"
    t.string "battle_status"
    t.boolean "warp_engaged", default: false
    t.boolean "shields_up", default: false
    t.datetime "red_alert_engaged_at"
    t.datetime "critical_status_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tenant_settings", primary_key: ["tenant_id", "key"], force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "key", null: false
    t.text "value"
    t.text "description"
    t.boolean "encrypted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_tenant_settings_on_key"
    t.index ["tenant_id"], name: "index_tenant_settings_on_tenant_id"
  end

  create_table "trips", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "owner_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.decimal "distance"
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "trip_type", limit: 20
    t.index ["owner_id"], name: "index_trips_on_owner_id"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vehicle_owners", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "owner_id", null: false
    t.date "ownership_start"
    t.date "ownership_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_vehicle_owners_on_owner_id"
    t.index ["vehicle_id"], name: "index_vehicle_owners_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name", limit: 100
    t.string "model", limit: 50
    t.integer "year", limit: 2
    t.decimal "price", precision: 10, scale: 2
    t.bigint "mileage"
    t.string "fuel_type", limit: 20
    t.string "transmission", limit: 20
    t.string "color", limit: 30
    t.string "vin", limit: 17
    t.text "description"
    t.boolean "available", default: true
    t.date "purchase_date"
    t.time "service_time"
    t.binary "image_data"
    t.string "condition", default: "used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "vehicle_type", limit: 20
    t.string "status", limit: 20
    t.index ["vin"], name: "index_vehicles_on_vin", unique: true
    t.index ["year", "model"], name: "index_vehicles_on_year_and_model"
  end

  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "diet_relationships", "species", column: "predator_id"
  add_foreign_key "diet_relationships", "species", column: "prey_id"
  add_foreign_key "fossil_discoveries", "dinosaurs"
  add_foreign_key "fossil_discoveries", "excavation_sites"
  add_foreign_key "maintenance_records", "vehicles"
  add_foreign_key "mission_waypoints", "missions"
  add_foreign_key "posts", "users"
  add_foreign_key "product_metrics", "products"
  add_foreign_key "spaceship_crew_members", "crew_members"
  add_foreign_key "spaceship_crew_members", "spaceships"
  add_foreign_key "spatial_coordinates", "spaceships"
  add_foreign_key "species", "families"
  add_foreign_key "trips", "owners"
  add_foreign_key "trips", "vehicles"
  add_foreign_key "vehicle_owners", "owners"
  add_foreign_key "vehicle_owners", "vehicles"
end
