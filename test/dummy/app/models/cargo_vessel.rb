# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "spaceships"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "class_type", type = "string" },
#   { name = "warp_capability", type = "boolean" },
#   { name = "status", type = "string" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "type", type = "string" },
#   { name = "cargo_capacity", type = "integer" },
#   { name = "cargo_type", type = "string" },
#   { name = "battle_status", type = "string" }
# ]
#
# [sti]
# type_column = "type"
# base_class = "Spaceship"
# type_value = "CargoVessel"
# siblings = ["StarfleetBattleCruiser"]
#
# [polymorphic]
# targets = [{ name = "comments", as = "commentable" }]
#
# [enums]
# status = { active = "active", maintenance = "maintenance", decommissioned = "decommissioned", obliterated = "obliterated" }
# cargo_type = { general = "general", refrigerated = "refrigerated", hazardous = "hazardous", livestock = "livestock" }
#
# [callbacks]
# before_save = [{ method = "validate_cargo_weight" }]
#
# notes = ["spaceship_crew_members:N_PLUS_ONE", "crew_members:N_PLUS_ONE", "missions:N_PLUS_ONE", "spatial_coordinates:N_PLUS_ONE", "comments:N_PLUS_ONE", "name:NOT_NULL", "class_type:NOT_NULL", "warp_capability:NOT_NULL", "status:NOT_NULL", "type:NOT_NULL", "cargo_capacity:NOT_NULL", "cargo_type:NOT_NULL", "battle_status:NOT_NULL", "warp_capability:DEFAULT", "status:DEFAULT", "battle_status:DEFAULT", "name:LIMIT", "class_type:LIMIT", "status:LIMIT", "type:LIMIT", "cargo_type:LIMIT", "battle_status:LIMIT", "class_type:INDEX", "status:INDEX", "type:INDEX", "cargo_type:INDEX", "battle_status:INDEX", "type:STI_NOT_NULL"]
# <rails-lens:schema:end>
class CargoVessel < Spaceship
  # Enums
  enum :cargo_type, {
    general: 'general',
    refrigerated: 'refrigerated',
    hazardous: 'hazardous',
    livestock: 'livestock'
  }, suffix: true

  # Validations
  validates :cargo_capacity, presence: true, numericality: { greater_than: 0 }
  validates :cargo_type, presence: true

  # Scopes
  scope :by_cargo_type, ->(type) { where(cargo_type: type) }
  scope :with_capacity_above, ->(capacity) { where('cargo_capacity > ?', capacity) }

  # Callbacks (in addition to inherited from Spaceship)
  before_save :validate_cargo_weight

  private

  def validate_cargo_weight
    # Validate cargo weight doesn't exceed capacity
    # errors.add(:cargo_weight, 'exceeds capacity') if cargo_weight > cargo_capacity
  end
end
