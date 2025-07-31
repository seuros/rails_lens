# frozen_string_literal: true

class CreateSpatialAnalysisView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW spatial_analysis AS
      SELECT 
        s.id AS spaceship_id,
        s.name AS spaceship_name,
        s.class_type,
        COUNT(sc.id) AS coordinate_records,
        ST_EXTENT(sc.location) AS coverage_area,
        AVG(sc.altitude) AS avg_altitude,
        MIN(sc.recorded_at) AS first_recorded,
        MAX(sc.recorded_at) AS last_recorded,
        EXTRACT(EPOCH FROM (MAX(sc.recorded_at) - MIN(sc.recorded_at))) / 3600 AS mission_duration_hours,
        COUNT(DISTINCT DATE(sc.recorded_at)) AS active_days
      FROM spaceships s
      LEFT JOIN spatial_coordinates sc ON s.id = sc.spaceship_id
      WHERE sc.id IS NOT NULL
      GROUP BY s.id, s.name, s.class_type
      ORDER BY COUNT(sc.id) DESC, s.name
    SQL

    # Add indexes for better performance
    execute 'CREATE INDEX index_spatial_analysis_on_spaceship_id ON spatial_analysis (spaceship_id)'
    execute 'CREATE INDEX index_spatial_analysis_on_coordinate_records ON spatial_analysis (coordinate_records)'
    execute 'CREATE INDEX index_spatial_analysis_on_mission_duration_hours ON spatial_analysis (mission_duration_hours)'
  end

  def down
    execute 'DROP MATERIALIZED VIEW IF EXISTS spatial_analysis'
  end
end