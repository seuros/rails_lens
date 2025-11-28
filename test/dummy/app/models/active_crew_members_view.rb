# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "active_crew_members"
# database_dialect = "PostgreSQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer", nullable = true },
#   { name = "name", type = "string", nullable = true },
#   { name = "rank", type = "string", nullable = true },
#   { name = "species", type = "string", nullable = true },
#   { name = "specialization", type = "string", nullable = true },
#   { name = "status", type = "string", nullable = true },
#   { name = "spaceship_id", type = "integer", nullable = true },
#   { name = "spaceship_name", type = "string", nullable = true },
#   { name = "position", type = "string", nullable = true },
#   { name = "assigned_at", type = "datetime", nullable = true }
# ]
#
# == View Information
# View Type: regular
# Updatable: No
# Definition: SELECT cm.id, cm.name, cm.rank, cm.species, cm.specialization, cm.status, scm.spaceship_id, s.name AS spaceship_name, scm."position", scm.assigned_at FROM ((crew_...
#
# == Notes
# - 👁️ View-backed model: read-only
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