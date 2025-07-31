# frozen_string_literal: true

class CreateFossilStatsView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE VIEW fossil_stats AS
      SELECT 
        es.id as excavation_site_id,
        es.name as site_name,
        es.location,
        es.coordinates,
        es.depth,
        es.soil_type,
        es.rock_formation,
        es.climate_ancient,
        es.active,
        COUNT(DISTINCT fd.id) as fossil_count,
        COUNT(DISTINCT fd.dinosaur_id) as unique_dinosaur_count,
        AVG(fd.completeness) as average_completeness,
        MAX(fd.completeness) as best_completeness,
        MIN(fd.completeness) as worst_completeness,
        GROUP_CONCAT(DISTINCT d.species) as species_found,
        GROUP_CONCAT(DISTINCT d.period) as periods_represented,
        CASE 
          WHEN COUNT(fd.id) = 0 THEN 'No Fossils'
          WHEN COUNT(fd.id) <= 5 THEN 'Few Fossils'
          WHEN COUNT(fd.id) <= 20 THEN 'Moderate Fossils'
          ELSE 'Rich Fossil Site'
        END as richness_level,
        CASE 
          WHEN es.active = 1 THEN 'Active Excavation'
          ELSE 'Inactive Site'
        END as excavation_status
      FROM excavation_sites es
      LEFT JOIN fossil_discoveries fd ON es.id = fd.excavation_site_id
      LEFT JOIN dinosaurs d ON fd.dinosaur_id = d.id
      GROUP BY es.id, es.name, es.location, es.coordinates, es.depth, es.soil_type, 
               es.rock_formation, es.climate_ancient, es.active
      ORDER BY COUNT(fd.id) DESC, es.name
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS fossil_stats'
  end
end