# frozen_string_literal: true

class CreateCrewMissionStatsView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE VIEW crew_mission_stats AS
      SELECT 
        cm.id,
        cm.name,
        cm.rank,
        cm.specialization,
        COUNT(DISTINCT scm.spaceship_id) AS ships_served,
        COUNT(DISTINCT m.id) AS missions_participated,
        MAX(scm.assigned_at) AS last_assignment,
        CASE 
          WHEN cm.rank IN ('Admiral', 'Captain', 'Commander') THEN 'Officer'
          WHEN cm.rank IN ('Lieutenant Commander', 'Lieutenant', 'Lieutenant JG') THEN 'Junior Officer'
          ELSE 'Crew'
        END AS rank_category
      FROM crew_members cm
      LEFT JOIN spaceship_crew_members scm ON cm.id = scm.crew_member_id
      LEFT JOIN missions m ON scm.spaceship_id = (SELECT id FROM spaceships WHERE name = m.name)
      GROUP BY cm.id, cm.name, cm.rank, cm.specialization
      ORDER BY COUNT(DISTINCT m.id) DESC, cm.rank, cm.name
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS crew_mission_stats'
  end
end