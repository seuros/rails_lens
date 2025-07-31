# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "spatial_analysis"
# database_dialect = "PostgreSQL"
# view_type = "materialized"
# updatable = false
# materialized = true
# refresh_strategy = "manual"
#
# columns = [
#   { name = "spaceship_id", type = "integer", nullable = true },
#   { name = "spaceship_name", type = "string", nullable = true },
#   { name = "class_type", type = "string", nullable = true },
#   { name = "coordinate_records", type = "integer", nullable = true },
#   { name = "coverage_area", type = "", nullable = true },
#   { name = "avg_altitude", type = "float", nullable = true },
#   { name = "first_recorded", type = "datetime", nullable = true },
#   { name = "last_recorded", type = "datetime", nullable = true },
#   { name = "mission_duration_hours", type = "decimal", nullable = true },
#   { name = "active_days", type = "integer", nullable = true }
# ]
#
# == View Information
# View Type: materialized
# Updatable: No
# Refresh Strategy: manual
# Definition: SELECT s.id AS spaceship_id, s.name AS spaceship_name, s.class_type, count(sc.id) AS coordinate_records, st_extent(sc.location) AS coverage_area, avg(sc.altitude) AS avg_altitude, ...
#
# == Notes
# - 👁️ View-backed model: read-only
# - 🔄 Materialized view: data may be stale until refreshed
# <rails-lens:schema:end>
# PostgreSQL Materialized View: Spatial coordinate analysis with PostGIS
class SpatialAnalysis < ApplicationRecord
  self.table_name = 'spatial_analysis'
  self.primary_key = 'spaceship_id'
  
  readonly
  
  # Association back to the spaceship
  belongs_to :spaceship, foreign_key: 'spaceship_id'
  
  # Scopes for analysis
  scope :long_missions, -> { where('mission_duration_hours > ?', 48) }
  scope :high_activity, -> { where('coordinate_records > ?', 100) }
  scope :recent_missions, -> { where('last_recorded > ?', 1.month.ago) }
  
  # Class method to refresh the materialized view
  def self.refresh!
    connection.execute('REFRESH MATERIALIZED VIEW spatial_analysis')
  end
  
  def self.refresh_concurrently!
    connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY spatial_analysis')
  rescue ActiveRecord::StatementInvalid
    refresh!
  end
  
  # Instance methods for data interpretation
  def mission_duration_days
    mission_duration_hours / 24.0 if mission_duration_hours
  end
  
  def activity_level
    case coordinate_records
    when 0..10 then 'Low'
    when 11..50 then 'Moderate'
    when 51..200 then 'High'
    else 'Very High'
    end
  end
end