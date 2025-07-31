# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "crew_mission_stats"
# database_dialect = "PostgreSQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer", nullable = true },
#   { name = "name", type = "string", nullable = true },
#   { name = "rank", type = "string", nullable = true },
#   { name = "specialization", type = "string", nullable = true },
#   { name = "ships_served", type = "integer", nullable = true },
#   { name = "missions_participated", type = "integer", nullable = true },
#   { name = "last_assignment", type = "datetime", nullable = true },
#   { name = "rank_category", type = "text", nullable = true }
# ]
#
# == View Information
# View Type: regular
# Updatable: No
# Definition: SELECT cm.id, cm.name, cm.rank, cm.specialization, count(DISTINCT scm.spaceship_id) AS ships_served, count(DISTINCT m.id) AS missions_participated, max(scm.assigned_at) AS last_...
#
# == Notes
# - 👁️ View-backed model: read-only
# <rails-lens:schema:end>
# PostgreSQL View: Complex crew mission statistics and analysis
class CrewMissionStats < ApplicationRecord
  self.table_name = 'crew_mission_stats'
  self.primary_key = 'id'
  
  readonly
  
  # Scopes for different rank categories
  scope :officers, -> { where(rank_category: 'Officer') }
  scope :junior_officers, -> { where(rank_category: 'Junior Officer') }
  scope :crew, -> { where(rank_category: 'Crew') }
  
  # Scope for active crew members with recent assignments
  scope :recently_active, -> { where('last_assignment > ?', 6.months.ago) }
  
  # Validation to prevent accidental writes
  validate :prevent_writes
  
  private
  
  def prevent_writes
    errors.add(:base, 'This is a read-only view') if new_record? || changed?
  end
end