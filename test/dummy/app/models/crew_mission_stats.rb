# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "crew_mission_stats"
# database_dialect = "PostgreSQL"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer" },
#   { name = "name", type = "string" },
#   { name = "rank", type = "string" },
#   { name = "specialization", type = "string" },
#   { name = "ships_served", type = "integer" },
#   { name = "missions_participated", type = "integer" },
#   { name = "last_assignment", type = "datetime" },
#   { name = "rank_category", type = "text" }
# ]
#
# [view]
# type = "regular"
# updatable = false
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