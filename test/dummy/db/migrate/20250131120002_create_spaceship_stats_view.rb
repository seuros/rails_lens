# frozen_string_literal: true

class CreateSpaceshipStatsView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE VIEW spaceship_stats AS
      SELECT 
        s.id,
        s.name,
        s.class_type,
        s.status,
        s.warp_capability,
        COUNT(DISTINCT scm.crew_member_id) FILTER (WHERE scm.active = true) as active_crew_count,
        COUNT(DISTINCT m.id) as mission_count,
        COUNT(DISTINCT sc.id) as coordinate_records,
        CASE 
          WHEN s.type = 'CargoVessel' THEN s.cargo_capacity::text || ' (' || COALESCE(s.cargo_type, 'Unknown') || ')'
          WHEN s.type = 'StarfleetBattleCruiser' THEN 'Battle Ready: ' || COALESCE(s.battle_status, 'Unknown')
          ELSE 'Standard Configuration'
        END as special_configuration
      FROM spaceships s
      LEFT JOIN spaceship_crew_members scm ON s.id = scm.spaceship_id
      LEFT JOIN missions m ON s.name = m.name
      LEFT JOIN spatial_coordinates sc ON s.id = sc.spaceship_id
      GROUP BY s.id, s.name, s.class_type, s.status, s.warp_capability, s.type, s.cargo_capacity, s.cargo_type, s.battle_status
      ORDER BY s.name
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS spaceship_stats'
  end
end