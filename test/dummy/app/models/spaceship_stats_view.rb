# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "spaceship_stats"
# database_dialect = "PostgreSQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer", nullable = true },
#   { name = "name", type = "string", nullable = true },
#   { name = "class_type", type = "string", nullable = true },
#   { name = "status", type = "string", nullable = true },
#   { name = "warp_capability", type = "boolean", nullable = true },
#   { name = "active_crew_count", type = "integer", nullable = true },
#   { name = "mission_count", type = "integer", nullable = true },
#   { name = "coordinate_records", type = "integer", nullable = true },
#   { name = "special_configuration", type = "text", nullable = true }
# ]
#
# == View Information
# View Type: regular
# Updatable: No
# Definition: SELECT s.id, s.name, s.class_type, s.status, s.warp_capability, count(DISTINCT scm.crew_member_id) FILTER (WHERE (scm.active = true)) AS active_crew_count, count(DISTINCT m.id) ...
#
# == Notes
# - 👁️ View-backed model: read-only
# <rails-lens:schema:end>
# PostgreSQL View: Comprehensive statistics for spaceships
class SpaceshipStatsView < ApplicationRecord
  self.table_name = 'spaceship_stats'
  self.primary_key = 'id'
  
  readonly
end