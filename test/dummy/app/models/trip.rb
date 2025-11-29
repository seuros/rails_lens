# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "trips"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "vehicle_id", type = "integer", null = false },
#   { name = "owner_id", type = "integer", null = false },
#   { name = "start_date", type = "date" },
#   { name = "end_date", type = "date" },
#   { name = "distance", type = "decimal" },
#   { name = "purpose", type = "string" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "trip_type", type = "string" }
# ]
#
# indexes = [
#   { name = "index_trips_on_owner_id", columns = ["owner_id"] },
#   { name = "index_trips_on_vehicle_id", columns = ["vehicle_id"] }
# ]
#
# foreign_keys = [
#   { column = "vehicle_id", references_table = "vehicles", references_column = "id", name = "fk_rails_272ac73176" },
#   { column = "owner_id", references_table = "owners", references_column = "id", name = "fk_rails_9b563cd750" }
# ]
#
# [callbacks]
# before_save = [{ method = "calculate_distance" }, { method = "set_fuel_consumption" }, { method = "update_trip_category" }]
# after_save = [{ method = "update_vehicle_mileage" }]
# after_destroy = [{ method = "revert_vehicle_mileage" }]
#
# notes = ["vehicle:COUNTER_CACHE", "distance:NOT_NULL", "purpose:NOT_NULL", "trip_type:NOT_NULL", "trip_type:INDEX"]
# <rails-lens:schema:end>
class Trip < VehicleRecord
  belongs_to :vehicle, inverse_of: :trips
  belongs_to :owner

  # Validations
  validates :start_date, presence: true
  validates :purpose, presence: true

  # Callbacks - Prepend ordering (calculate_distance runs first due to prepend)
  before_save :calculate_distance, prepend: true
  before_save :set_fuel_consumption
  before_save :update_trip_category

  after_save :update_vehicle_mileage
  after_destroy :revert_vehicle_mileage

  private

  def calculate_distance
    return unless start_location && end_location

    self.distance = GeoCalculator.distance_between(start_location, end_location)
  end

  def set_fuel_consumption
    return unless distance && vehicle

    self.fuel_consumed = distance * vehicle.fuel_efficiency_rate
  end

  def update_trip_category
    self.trip_type = distance.to_i > 100 ? 'long_distance' : 'local'
  end

  def update_vehicle_mileage
    vehicle.increment!(:mileage, distance.to_i) if saved_change_to_distance?
  end

  def revert_vehicle_mileage
    vehicle.decrement!(:mileage, distance.to_i) if distance.present?
  end
end

