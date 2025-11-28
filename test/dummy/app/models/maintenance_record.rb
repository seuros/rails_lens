# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "maintenance_records"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "vehicle_id", type = "integer", nullable = false },
#   { name = "service_type", type = "string", nullable = true },
#   { name = "cost", type = "decimal", nullable = true },
#   { name = "service_date", type = "date", nullable = true },
#   { name = "notes", type = "text", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# indexes = [
#   { name = "index_maintenance_records_on_vehicle_id", columns = ["vehicle_id"] }
# ]
#
# foreign_keys = [
#   { column = "vehicle_id", references_table = "vehicles", references_column = "id", name = "fk_rails_6e208080fe" }
# ]
#
# triggers = [
#   { name = "decrement_vehicle_maintenance_count", event = "DELETE", timing = "AFTER", function = "inline", for_each = "ROW" },
#   { name = "increment_vehicle_maintenance_count", event = "INSERT", timing = "AFTER", function = "inline", for_each = "ROW" }
# ]
#
# == Enums
# - service_type: { oil_change: "oil_change", tire_rotation: "tire_rotation", brake_service: "brake_service", transmission: "transmission", engine_repair: "engine_repair", inspection: "inspection", warranty: "warranty", recall: "recall" } (string)
#
# == Notes
# - Consider adding counter cache for 'vehicle'
# - Column 'service_type' should probably have NOT NULL constraint
# - Column 'cost' should probably have NOT NULL constraint
# - Column 'notes' should probably have NOT NULL constraint
# - Column 'service_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class MaintenanceRecord < VehicleRecord
  # Enums
  enum :service_type, {
    oil_change: 'oil_change',
    tire_rotation: 'tire_rotation',
    brake_service: 'brake_service',
    transmission: 'transmission',
    engine_repair: 'engine_repair',
    inspection: 'inspection',
    warranty: 'warranty',
    recall: 'recall'
  }, suffix: true

  # Associations
  belongs_to :vehicle, inverse_of: :maintenance_records

  # Validations
  validates :service_type, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :service_date, presence: true

  # Scopes
  scope :recent, -> { order(service_date: :desc) }
  scope :by_type, ->(type) { where(service_type: type) }
  scope :expensive, -> { where('cost > ?', 500) }
  scope :for_year, ->(year) { where(service_date: Date.new(year).beginning_of_year..Date.new(year).end_of_year) }
end

