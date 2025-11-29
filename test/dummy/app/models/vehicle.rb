# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "vehicles"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "model", type = "string" },
#   { name = "year", type = "integer" },
#   { name = "price", type = "decimal" },
#   { name = "mileage", type = "integer" },
#   { name = "fuel_type", type = "string" },
#   { name = "transmission", type = "string" },
#   { name = "color", type = "string" },
#   { name = "vin", type = "string" },
#   { name = "description", type = "text" },
#   { name = "available", type = "boolean", default = "1" },
#   { name = "purchase_date", type = "date" },
#   { name = "service_time", type = "time" },
#   { name = "image_data", type = "binary" },
#   { name = "condition", type = "string", default = "used" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "vehicle_type", type = "string" },
#   { name = "status", type = "string" },
#   { name = "maintenance_count", type = "integer", null = false, default = "0" }
# ]
#
# [enums]
# vehicle_type = { car = "car", truck = "truck", motorcycle = "motorcycle", bus = "bus", van = "van", suv = "suv", electric = "electric", hybrid = "hybrid" }
# status = { active = "active", maintenance = "maintenance", impounded = "impounded", scrapped = "scrapped" }
#
# [callbacks]
# before_validation = [{ method = "set_defaults" }]
# before_save = [{ method = "update_mileage_category", if = ["mileage_changed?"], unless = ["new_record?"] }]
# after_update = [{ method = "schedule_maintenance", if = ["proc"] }]
#
# notes = ["manufacturer_id:INDEX", "manufacturer_id:FK_CONSTRAINT", "vehicle_owners:N_PLUS_ONE", "owners:N_PLUS_ONE", "maintenance_records:N_PLUS_ONE", "trips:N_PLUS_ONE", "manufacturer:COUNTER_CACHE", "name:NOT_NULL", "model:NOT_NULL", "year:NOT_NULL", "price:NOT_NULL", "mileage:NOT_NULL", "fuel_type:NOT_NULL", "transmission:NOT_NULL", "color:NOT_NULL", "vin:NOT_NULL", "description:NOT_NULL", "available:NOT_NULL", "service_time:NOT_NULL", "image_data:NOT_NULL", "condition:NOT_NULL", "vehicle_type:NOT_NULL", "status:NOT_NULL", "status:DEFAULT", "fuel_type:INDEX", "vehicle_type:INDEX", "status:INDEX", "description:STORAGE"]
# <rails-lens:schema:end>
class Vehicle < VehicleRecord
  # Enums
  enum :vehicle_type, {
    car: 'car',
    truck: 'truck',
    motorcycle: 'motorcycle',
    bus: 'bus',
    van: 'van',
    suv: 'suv',
    electric: 'electric',
    hybrid: 'hybrid'
  }, suffix: true

  enum :status, {
    active: 'active',
    maintenance: 'maintenance',
    impounded: 'impounded',
    scrapped: 'scrapped'
  }, suffix: true

  # Associations
  belongs_to :manufacturer, inverse_of: :vehicles
  has_many :vehicle_owners, dependent: :destroy, inverse_of: :vehicle
  has_many :owners, through: :vehicle_owners
  has_many :maintenance_records, dependent: :destroy, inverse_of: :vehicle
  has_many :trips, dependent: :destroy, inverse_of: :vehicle

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :model, presence: true, length: { maximum: 50 }
  validates :year, presence: true, numericality: { greater_than: 1900, less_than_or_equal_to: Date.current.year + 1 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mileage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fuel_type, presence: true

  validates :transmission, presence: true
  validates :color, presence: true
  validates :vin, presence: true, length: { is: 17 }, uniqueness: true
  validates :available, inclusion: { in: [true, false] }
  validates :purchase_date, presence: true
  validates :condition, presence: true
  validates :vehicle_type, presence: true
  validates :status, presence: true

  # Scopes
  scope :available, -> { where(available: true) }
  scope :by_type, ->(type) { where(vehicle_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_defaults, on: :create
  before_save :update_mileage_category, if: :mileage_changed?, unless: :new_record?
  after_update :schedule_maintenance, if: -> { mileage > 50_000 }

  private

  def set_defaults
    self.available = true if available.nil?
    self.condition ||= 'used'
  end

  def update_mileage_category
    self.condition = mileage > 100_000 ? 'high_mileage' : 'used'
  end

  def schedule_maintenance
    MaintenanceScheduler.schedule_checkup(self) if mileage_previously_changed?
  end
end

