# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "active_crew_members"
# database_dialect = "PostgreSQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer" },
#   { name = "name", type = "string" },
#   { name = "rank", type = "string" },
#   { name = "species", type = "string" },
#   { name = "specialization", type = "string" },
#   { name = "status", type = "string" },
#   { name = "spaceship_id", type = "integer" },
#   { name = "spaceship_name", type = "string" },
#   { name = "position", type = "string" },
#   { name = "assigned_at", type = "datetime" }
# ]
#
# [view]
# type = "regular"
# updatable = false
# <rails-lens:schema:end>
# PostgreSQL View: Shows active crew members with their current assignments
class ActiveCrewMembersView < ApplicationRecord
  self.table_name = 'active_crew_members'
  self.primary_key = 'id'
  
  # This model is backed by a PostgreSQL view and should be read-only
  def readonly?
    true
  end
  
  def self.readonly_model?
    true
  end
end