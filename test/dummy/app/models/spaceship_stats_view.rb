# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "spaceship_stats"
# database_dialect = "PostgreSQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer" },
#   { name = "name", type = "string" },
#   { name = "class_type", type = "string" },
#   { name = "status", type = "string" },
#   { name = "warp_capability", type = "boolean" },
#   { name = "active_crew_count", type = "integer" },
#   { name = "mission_count", type = "integer" },
#   { name = "coordinate_records", type = "integer" },
#   { name = "special_configuration", type = "text" }
# ]
#
# [view]
# type = "regular"
# updatable = false
# <rails-lens:schema:end>
# PostgreSQL View: Comprehensive statistics for spaceships
class SpaceshipStatsView < ApplicationRecord
  self.table_name = 'spaceship_stats'
  self.primary_key = 'id'
  
  readonly
end