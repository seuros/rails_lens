# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "vehicle_performance_metrics"
# database_dialect = "MySQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer", nullable = false, default = "0" },
#   { name = "name", type = "string", nullable = true },
#   { name = "model", type = "string", nullable = true },
#   { name = "year", type = "integer", nullable = true },
#   { name = "vehicle_type", type = "string", nullable = true },
#   { name = "fuel_type", type = "string", nullable = true },
#   { name = "price", type = "decimal", nullable = true },
#   { name = "mileage", type = "integer", nullable = true },
#   { name = "maintenance_events", type = "integer", nullable = false, default = "0" },
#   { name = "total_maintenance_cost", type = "decimal", nullable = false, default = "0" },
#   { name = "trip_count", type = "integer", nullable = false, default = "0" },
#   { name = "total_distance", type = "decimal", nullable = false, default = "0" },
#   { name = "cost_per_mile", type = "decimal", nullable = true },
#   { name = "days_owned", type = "integer", nullable = true },
#   { name = "maintenance_category", type = "string", nullable = false, default = "" },
#   { name = "availability_tier", type = "string", nullable = false, default = "" }
# ]
#
# view_dependencies = ["maintenance_records", "trips", "vehicles"]
#
# == View Information
# View Type: regular
# Updatable: No
# Dependencies: maintenance_records, trips, vehicles
# Definition: select `v`.`id` AS `id`,`v`.`name` AS `name`,`v`.`model` AS `model`,`v`.`year` AS `year`,`v`.`vehicle_type` AS `vehicle_type`,`v`.`fuel_type` AS `fuel_type`,`v`.`price` AS `price`,`v`.`mileage` AS `mil...
#
# == Notes
# - 👁️ View-backed model: read-only
# <rails-lens:schema:end>
# MySQL View: Comprehensive vehicle performance and cost analysis
class VehiclePerformanceMetrics < VehicleRecord
  self.table_name = 'vehicle_performance_metrics'
  self.primary_key = 'id'
  
  readonly
  
  # Association back to the vehicle
  belongs_to :vehicle, foreign_key: 'id'
  
  # Scopes for filtering
  scope :premium_tier, -> { where(availability_tier: 'Premium') }
  scope :low_maintenance, -> { where(maintenance_category: 'Low Maintenance') }
  scope :fuel_efficient, -> { where(fuel_type: ['hybrid', 'electric']) }
  scope :cost_effective, -> { where('cost_per_mile < ?', 0.50) }
  
  # Scopes by vehicle characteristics
  scope :recent_models, -> { where('year >= ?', 2020) }
  scope :high_mileage, -> { where('total_distance > ?', 50000) }
  
  # Instance methods for business logic
  def efficiency_rating
    case cost_per_mile
    when 0..0.20 then 'Excellent'
    when 0.21..0.40 then 'Good'
    when 0.41..0.60 then 'Fair'
    else 'Poor'
    end
  end
  
  def maintenance_frequency
    return 0 if days_owned.zero?
    
    (maintenance_events.to_f / days_owned * 365).round(2)
  end
  
  def daily_distance_average
    return 0 if days_owned.zero?
    
    (total_distance.to_f / days_owned).round(2)
  end
end