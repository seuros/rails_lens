# frozen_string_literal: true

class CreateFossilDiscoveryTimelineView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE VIEW fossil_discovery_timeline AS
      SELECT 
        fd.id,
        fd.discovered_at,
        fd.completeness,
        fd.condition,
        d.name as dinosaur_name,
        d.species,
        d.period,
        d.diet,
        es.name as excavation_site,
        es.location as site_location,
        es.depth as excavation_depth,
        es.soil_type,
        es.rock_formation,
        es.climate_ancient,
        CASE 
          WHEN fd.completeness >= 90 THEN 'Nearly Complete'
          WHEN fd.completeness >= 70 THEN 'Well Preserved'
          WHEN fd.completeness >= 50 THEN 'Moderately Complete'
          WHEN fd.completeness >= 25 THEN 'Fragmentary'
          ELSE 'Trace Evidence'
        END as completeness_category,
        strftime('%Y', fd.discovered_at) as discovery_year,
        strftime('%m', fd.discovered_at) as discovery_month,
        CASE 
          WHEN d.period = 'Triassic' THEN 1
          WHEN d.period = 'Jurassic' THEN 2
          WHEN d.period = 'Cretaceous' THEN 3
          ELSE 4
        END as period_order
      FROM fossil_discoveries fd
      INNER JOIN dinosaurs d ON fd.dinosaur_id = d.id
      INNER JOIN excavation_sites es ON fd.excavation_site_id = es.id
      ORDER BY fd.discovered_at DESC, fd.completeness DESC
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS fossil_discovery_timeline'
  end
end