# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "maintenance_records"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "vehicle_id", type = "integer", null = false },
#   { name = "service_type", type = "string" },
#   { name = "cost", type = "decimal" },
#   { name = "service_date", type = "date" },
#   { name = "notes", type = "text" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
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
# [enums]
# service_type = { oil_change = "oil_change", tire_rotation = "tire_rotation", brake_service = "brake_service", transmission = "transmission", engine_repair = "engine_repair", inspection = "inspection", warranty = "warranty", recall = "recall" }
#
# [callbacks]
# after_create = [{ method = "schedule_next_appointment" }, { method = "update_vehicle_last_service" }]
# after_destroy = [{ method = "recalculate_vehicle_costs" }]
#
# notes = ["vehicle:COUNTER_CACHE", "service_type:NOT_NULL", "cost:NOT_NULL", "notes:NOT_NULL", "service_type:INDEX", "notes:STORAGE"]
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

  # Callbacks - Cross-record effects (updating related records)
  after_create :update_vehicle_last_service
  after_create :schedule_next_appointment
  after_destroy :recalculate_vehicle_costs

  private

  def update_vehicle_last_service
    vehicle.update_column(:last_service_date, service_date)
  end

  def schedule_next_appointment
    ServiceScheduler.schedule_followup(vehicle, service_type, service_date + 6.months)
  end

  def recalculate_vehicle_costs
    vehicle.update_column(:total_maintenance_cost, vehicle.maintenance_records.sum(:cost))
  end
end

