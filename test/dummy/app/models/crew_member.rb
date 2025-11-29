# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "crew_members"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "rank", type = "string" },
#   { name = "species", type = "string" },
#   { name = "birth_planet", type = "string" },
#   { name = "service_record", type = "text" },
#   { name = "active", type = "boolean" },
#   { name = "joined_starfleet_at", type = "datetime" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "status", type = "string" },
#   { name = "specialization", type = "string" }
# ]
#
# [enums]
# status = { active = "active", on_leave = "on_leave", injured = "injured", mia = "mia", kia = "kia" }
# specialization = { command = "command", science = "science", engineering = "engineering", medical = "medical", security = "security", communications = "communications" }
#
# [callbacks]
# before_update = [{ method = "prevent_status_change", if = ["deceased?"] }]
# before_destroy = [{ method = "check_active_missions" }]
#
# notes = ["home_planet_id:INDEX", "home_planet_id:FK_CONSTRAINT", "spaceship_crew_members:INVERSE_OF", "home_planet:INVERSE_OF", "spaceship_crew_members:N_PLUS_ONE", "spaceships:N_PLUS_ONE", "name:NOT_NULL", "rank:NOT_NULL", "species:NOT_NULL", "birth_planet:NOT_NULL", "service_record:NOT_NULL", "active:NOT_NULL", "status:NOT_NULL", "specialization:NOT_NULL", "active:DEFAULT", "status:DEFAULT", "name:LIMIT", "rank:LIMIT", "species:LIMIT", "birth_planet:LIMIT", "specialization:LIMIT", "status:INDEX", "service_record:STORAGE"]
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

  # Callbacks
  before_destroy :check_active_missions
  before_update :prevent_status_change, if: :deceased?

  private

  def check_active_missions
    throw(:abort) if spaceships.joins(:missions).where(missions: { status: 'active' }).exists?
  end

  def prevent_status_change
    throw(:abort) if status_changed?
  end

  def deceased?
    status == 'kia'
  end
end

