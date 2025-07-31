# frozen_string_literal: true

class CreateVehiclePerformanceMetricsView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
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
  end

  def down
    execute 'DROP VIEW IF EXISTS vehicle_performance_metrics'
  end
end