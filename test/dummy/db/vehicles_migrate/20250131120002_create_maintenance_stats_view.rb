# frozen_string_literal: true

class CreateMaintenanceStatsView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
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

  def down
    execute 'DROP VIEW IF EXISTS maintenance_stats'
  end
end