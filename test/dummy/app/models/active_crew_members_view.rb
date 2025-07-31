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
#   { name = "birth_planet", type = "string", nullable = true },
#   { name = "specialization", type = "string", nullable = true },
#   { name = "joined_starfleet_at", type = "datetime", nullable = true },
#   { name = "active_assignments", type = "integer", nullable = true },
#   { name = "assigned_spaceships", type = "string", nullable = true }
# ]
#
# == View Information
# View Type: regular
# Updatable: No
# Definition: SELECT cm.id, cm.name, cm.rank, cm.species, cm.birth_planet, cm.specialization, cm.joined_starfleet_at, count(scm.id) AS active_assignments, array_agg(DISTINCT s.name) F...
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