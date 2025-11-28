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

ActiveRecord::Schema[8.0].define(version: 2025_01_31_120002) do
  create_table "alerts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "severity"
    t.string "alert_type"
    t.text "description"
    t.boolean "resolved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "announcements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "body"
    t.string "audience"
    t.datetime "scheduled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audit_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "table_name", null: false
    t.string "record_id", null: false
    t.string "action", null: false
    t.string "user_id"
    t.string "user_email"
    t.json "changes"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["table_name", "record_id"], name: "index_audit_logs_on_table_name_and_record_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "audit_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "value"
    t.text "description"
    t.boolean "enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_audit_settings_on_key", unique: true
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "user_id", null: false
    t.bigint "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "crew_members", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "diet_relationships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "dinosaurs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "species"
    t.string "period"
    t.string "diet"
    t.decimal "length", precision: 10
    t.decimal "weight", precision: 10
    t.date "discovered_at"
    t.date "extinction_date"
    t.integer "fossil_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.boolean "published"
    t.string "entryable_type"
    t.bigint "entryable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "excavation_sites", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.string "coordinates"
    t.decimal "depth", precision: 10
    t.string "soil_type"
    t.date "discovered_at"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rock_formation", limit: 20
    t.string "climate_ancient", limit: 20
  end

  create_table "families", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "classification"
    t.string "taxonomic_rank"
    t.integer "parent_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "family_hierarchies", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.integer "generations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "forgotten_wars", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "start_year"
    t.integer "end_year"
    t.string "region"
    t.string "war_type"
    t.string "outcome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fossil_discoveries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "dinosaur_id", null: false
    t.bigint "excavation_site_id", null: false
    t.date "discovered_at"
    t.string "condition"
    t.decimal "completeness", precision: 10
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preservation_quality", limit: 20
    t.string "fossil_type", limit: 20
    t.index ["dinosaur_id"], name: "index_fossil_discoveries_on_dinosaur_id"
    t.index ["excavation_site_id"], name: "index_fossil_discoveries_on_excavation_site_id"
  end

  create_table "home_planet_hierarchies", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.integer "generations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "home_planets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "galaxy"
    t.string "coordinates"
    t.decimal "habitability_score", precision: 5, scale: 2
    t.string "climate_type"
    t.bigint "population"
    t.date "established_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "classification", limit: 20
    t.string "hierarchy_type", limit: 20
  end

  create_table "maintenance_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.string "service_type"
    t.decimal "cost", precision: 10
    t.date "service_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_maintenance_records_on_vehicle_id"
  end

  create_table "manufacturer_hierarchies", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.integer "generations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "manufacturers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.integer "founded_year"
    t.text "headquarters"
    t.string "website"
    t.decimal "annual_revenue", precision: 10
    t.boolean "active"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", limit: 20
    t.string "company_type", limit: 20
  end

  create_table "messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.string "recipient"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mission_waypoints", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "missions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "objective"
    t.string "status"
    t.integer "priority"
    t.date "start_date"
    t.date "end_date"
    t.integer "estimated_duration"
    t.string "classification_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "classification", limit: 20
  end

  create_table "owners", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.date "date_of_birth"
    t.string "license_number"
    t.integer "credit_score"
    t.decimal "net_worth", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "license_class", limit: 20
  end

  create_table "posts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.bigint "user_id", null: false
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_posts_on_published"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "product_metrics", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.integer "views", default: 0, null: false
    t.integer "purchases", default: 0, null: false
    t.decimal "revenue", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spaceship_crew_members", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "spaceships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "spatial_coordinates", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "location"
    t.string "coordinates"
    t.text "sensor_data"
    t.text "metadata"
    t.string "ip_address"
    t.string "tracking_id"
    t.float "altitude"
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.timestamp "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "spaceship_id", null: false
    t.index ["spaceship_id"], name: "index_spatial_coordinates_on_spaceship_id"
  end

  create_table "species", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "starfleet_battle_cruisers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "tenant_settings", primary_key: ["tenant_id", "key"], charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "trips", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "owner_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.decimal "distance", precision: 10
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "trip_type", limit: 20
    t.index ["owner_id"], name: "index_trips_on_owner_id"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vehicle_owners", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "owner_id", null: false
    t.date "ownership_start"
    t.date "ownership_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_vehicle_owners_on_owner_id"
    t.index ["vehicle_id"], name: "index_vehicle_owners_on_vehicle_id"
  end

  create_table "vehicles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.integer "maintenance_count", default: 0, null: false
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
  add_foreign_key "spaceship_crew_members", "crew_members"
  add_foreign_key "spaceship_crew_members", "spaceships"
  add_foreign_key "spatial_coordinates", "spaceships"
  add_foreign_key "species", "families"
  add_foreign_key "trips", "owners"
  add_foreign_key "trips", "vehicles"
  add_foreign_key "vehicle_owners", "owners"
  add_foreign_key "vehicle_owners", "vehicles"

  # MySQL triggers for maintenance_count (manually maintained)
  execute <<-SQL
    CREATE TRIGGER increment_vehicle_maintenance_count
      AFTER INSERT ON maintenance_records FOR EACH ROW
      UPDATE vehicles SET maintenance_count = maintenance_count + 1 WHERE id = NEW.vehicle_id
  SQL

  execute <<-SQL
    CREATE TRIGGER decrement_vehicle_maintenance_count
      AFTER DELETE ON maintenance_records FOR EACH ROW
      UPDATE vehicles SET maintenance_count = GREATEST(maintenance_count - 1, 0) WHERE id = OLD.vehicle_id
  SQL

  # MySQL views (manually maintained)
  execute <<-SQL
    CREATE VIEW vehicle_performance_metrics AS
    SELECT
      v.id,
      v.name,
      v.model,
      v.year,
      v.vehicle_type,
      v.fuel_type,
      v.price,
      v.mileage,
      COUNT(DISTINCT mr.id) as maintenance_events,
      COALESCE(SUM(mr.cost), 0) as total_maintenance_cost,
      COUNT(DISTINCT t.id) as trip_count,
      COALESCE(SUM(t.distance), 0) as total_distance,
      CASE
        WHEN COALESCE(SUM(t.distance), 0) > 0 THEN
          ROUND(COALESCE(SUM(mr.cost), 0) / SUM(t.distance), 4)
        ELSE NULL
      END as cost_per_mile,
      DATEDIFF(CURDATE(), v.created_at) as days_owned,
      CASE
        WHEN COUNT(mr.id) = 0 THEN 'No Maintenance'
        WHEN COUNT(mr.id) <= 2 THEN 'Low Maintenance'
        WHEN COUNT(mr.id) <= 5 THEN 'Regular Maintenance'
        ELSE 'High Maintenance'
      END as maintenance_category,
      CASE
        WHEN v.available = 1 AND v.condition = 'excellent' THEN 'Premium'
        WHEN v.available = 1 AND v.condition = 'good' THEN 'Standard'
        WHEN v.available = 1 THEN 'Basic'
        ELSE 'Unavailable'
      END as availability_tier
    FROM vehicles v
    LEFT JOIN maintenance_records mr ON v.id = mr.vehicle_id
    LEFT JOIN trips t ON v.id = t.vehicle_id
    GROUP BY v.id, v.name, v.model, v.year, v.vehicle_type, v.fuel_type, v.price, v.mileage, v.available, v.condition, v.created_at
    ORDER BY cost_per_mile ASC, total_distance DESC
  SQL

  execute <<-SQL
    CREATE VIEW maintenance_stats AS
    SELECT
      mr.vehicle_id,
      v.name as vehicle_name,
      v.model,
      v.year,
      COUNT(mr.id) as maintenance_count,
      SUM(mr.cost) as total_cost,
      AVG(mr.cost) as average_cost,
      MIN(mr.service_date) as first_service_date,
      MAX(mr.service_date) as last_service_date,
      GROUP_CONCAT(DISTINCT mr.service_type ORDER BY mr.service_date SEPARATOR ', ') as service_types,
      CASE
        WHEN COUNT(mr.id) = 0 THEN 'No Maintenance'
        WHEN COUNT(mr.id) <= 2 THEN 'Low Maintenance'
        WHEN COUNT(mr.id) <= 5 THEN 'Regular Maintenance'
        ELSE 'High Maintenance'
      END as maintenance_level,
      CASE
        WHEN MAX(mr.service_date) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH) THEN 'Service Due'
        WHEN MAX(mr.service_date) < DATE_SUB(CURDATE(), INTERVAL 3 MONTH) THEN 'Service Soon'
        ELSE 'Recently Serviced'
      END as service_status
    FROM vehicles v
    LEFT JOIN maintenance_records mr ON v.id = mr.vehicle_id
    GROUP BY mr.vehicle_id, v.name, v.model, v.year
    ORDER BY total_cost DESC, maintenance_count DESC
  SQL
end
