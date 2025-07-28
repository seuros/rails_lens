# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "crew_members"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "rank", type = "string", nullable = true },
#   { name = "species", type = "string", nullable = true },
#   { name = "birth_planet", type = "string", nullable = true },
#   { name = "service_record", type = "text", nullable = true },
#   { name = "active", type = "boolean", nullable = true },
#   { name = "joined_starfleet_at", type = "datetime", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "status", type = "string", nullable = true },
#   { name = "specialization", type = "string", nullable = true }
# ]
#
# == Enums
# - status: { active: "active", on_leave: "on_leave", injured: "injured", mia: "mia", kia: "kia" } (string)
# - specialization: { command: "command", science: "science", engineering: "engineering", medical: "medical", security: "security", communications: "communications" } (string)
#
# == Notes
# - Missing index on foreign key 'home_planet_id'
# - Missing foreign key constraint on 'home_planet_id' referencing 'home_planets'
# - Association 'spaceship_crew_members' should specify inverse_of
# - Association 'home_planet' should specify inverse_of
# - Association 'spaceship_crew_members' has N+1 query risk. Consider using includes/preload
# - Association 'spaceships' has N+1 query risk. Consider using includes/preload
# - Column 'name' should probably have NOT NULL constraint
# - Column 'rank' should probably have NOT NULL constraint
# - Column 'species' should probably have NOT NULL constraint
# - Column 'birth_planet' should probably have NOT NULL constraint
# - Column 'service_record' should probably have NOT NULL constraint
# - Column 'active' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - Column 'specialization' should probably have NOT NULL constraint
# - Boolean column 'active' should have a default value
# - Status column 'status' should have a default value
# - String column 'name' has no length limit - consider adding one
# - String column 'rank' has no length limit - consider adding one
# - String column 'species' has no length limit - consider adding one
# - String column 'birth_planet' has no length limit - consider adding one
# - String column 'specialization' has no length limit - consider adding one
# - Column 'status' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class CrewMember < ApplicationRecord
  # Enums
  enum :status, {
    active: 'active',
    on_leave: 'on_leave',
    injured: 'injured',
    mia: 'mia',
    kia: 'kia'
  }, suffix: true

  enum :specialization, {
    command: 'command',
    science: 'science',
    engineering: 'engineering',
    medical: 'medical',
    security: 'security',
    communications: 'communications'
  }

  # Associations
  has_many :spaceship_crew_members, dependent: :destroy
  has_many :spaceships, through: :spaceship_crew_members
  belongs_to :home_planet, optional: true

  # Validations
  validates :name, presence: true
  validates :rank, presence: true
  validates :species, presence: true
  validates :birth_planet, presence: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_rank, -> { order(:rank) }
end

