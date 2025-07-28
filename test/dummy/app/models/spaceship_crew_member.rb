# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "spaceship_crew_members"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "spaceship_id", type = "integer", nullable = false },
#   { name = "crew_member_id", type = "integer", nullable = false },
#   { name = "position", type = "string", nullable = true },
#   { name = "assigned_at", type = "datetime", nullable = true },
#   { name = "active", type = "boolean", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# indexes = [
#   { name = "index_spaceship_crew_members_on_crew_member_id", columns = ["crew_member_id"] },
#   { name = "index_spaceship_crew_members_on_spaceship_id", columns = ["spaceship_id"] }
# ]
#
# foreign_keys = [
#   { column = "crew_member_id", references_table = "crew_members", references_column = "id", name = "fk_rails_23b4e4c959" },
#   { column = "spaceship_id", references_table = "spaceships", references_column = "id", name = "fk_rails_7135c9d1a6" }
# ]
#
# == Notes
# - Consider adding counter cache for 'spaceship'
# - Consider adding counter cache for 'crew_member'
# - Column 'position' should probably have NOT NULL constraint
# - Column 'active' should probably have NOT NULL constraint
# - Boolean column 'active' should have a default value
# - String column 'position' has no length limit - consider adding one
# <rails-lens:schema:end>
class SpaceshipCrewMember < ApplicationRecord
  # Associations
  belongs_to :spaceship, inverse_of: :spaceship_crew_members
  belongs_to :crew_member, inverse_of: :spaceship_crew_members

  # Validations
  validates :position, presence: true
  validates :spaceship_id, uniqueness: { scope: %i[crew_member_id active],
                                         message: 'crew member is already assigned to this spaceship' }, if: :active?

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_position, ->(position) { where(position: position) }
  scope :recent_assignments, -> { order(assigned_at: :desc) }

  # Callbacks
  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.active = true if active.nil?
    self.assigned_at ||= Time.current
  end

end

