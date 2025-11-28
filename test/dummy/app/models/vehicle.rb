# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "vehicles"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "model", type = "string", nullable = true },
#   { name = "year", type = "integer", nullable = true },
#   { name = "price", type = "decimal", nullable = true },
#   { name = "mileage", type = "integer", nullable = true },
#   { name = "fuel_type", type = "string", nullable = true },
#   { name = "transmission", type = "string", nullable = true },
#   { name = "color", type = "string", nullable = true },
#   { name = "vin", type = "string", nullable = true },
#   { name = "description", type = "text", nullable = true },
#   { name = "available", type = "boolean", nullable = true, default = "1" },
#   { name = "purchase_date", type = "date", nullable = true },
#   { name = "service_time", type = "time", nullable = true },
#   { name = "image_data", type = "binary", nullable = true },
#   { name = "condition", type = "string", nullable = true, default = "used" },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "vehicle_type", type = "string", nullable = true },
#   { name = "status", type = "string", nullable = true },
#   { name = "maintenance_count", type = "integer", nullable = false, default = "0" }
# ]
#
# == Enums
# - vehicle_type: { car: "car", truck: "truck", motorcycle: "motorcycle", bus: "bus", van: "van", suv: "suv", electric: "electric", hybrid: "hybrid" } (string)
# - status: { active: "active", maintenance: "maintenance", impounded: "impounded", scrapped: "scrapped" } (string)
#
# == Notes
# - Missing index on foreign key 'manufacturer_id'
# - Missing foreign key constraint on 'manufacturer_id' referencing 'manufacturers'
# - Association 'vehicle_owners' has N+1 query risk. Consider using includes/preload
# - Association 'owners' has N+1 query risk. Consider using includes/preload
# - Association 'maintenance_records' has N+1 query risk. Consider using includes/preload
# - Association 'trips' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'manufacturer'
# - Column 'name' should probably have NOT NULL constraint
# - Column 'model' should probably have NOT NULL constraint
# - Column 'year' should probably have NOT NULL constraint
# - Column 'price' should probably have NOT NULL constraint
# - Column 'mileage' should probably have NOT NULL constraint
# - Column 'fuel_type' should probably have NOT NULL constraint
# - Column 'transmission' should probably have NOT NULL constraint
# - Column 'color' should probably have NOT NULL constraint
# - Column 'vin' should probably have NOT NULL constraint
# - Column 'description' should probably have NOT NULL constraint
# - Column 'available' should probably have NOT NULL constraint
# - Column 'service_time' should probably have NOT NULL constraint
# - Column 'image_data' should probably have NOT NULL constraint
# - Column 'condition' should probably have NOT NULL constraint
# - Column 'vehicle_type' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - Status column 'status' should have a default value
# - Large text column 'description' is frequently queried - consider separate storage
# - Column 'fuel_type' is commonly used in queries - consider adding an index
# - Column 'vehicle_type' is commonly used in queries - consider adding an index
# - Column 'status' is commonly used in queries - consider adding an index
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

  private

  def set_defaults
    self.available = true if available.nil?
    self.condition ||= 'used'
  end
end

