# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "spaceships"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "class_type", type = "string", nullable = true },
#   { name = "warp_capability", type = "boolean", nullable = true },
#   { name = "status", type = "string", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "type", type = "string", nullable = true },
#   { name = "cargo_capacity", type = "integer", nullable = true },
#   { name = "cargo_type", type = "string", nullable = true },
#   { name = "battle_status", type = "string", nullable = true }
# ]
#
# == Inheritance (STI)
# Type Column: type
# Base Class: Spaceship
# Type Value: CargoVessel
# Sibling Classes: StarfleetBattleCruiser
#
# == Polymorphic Associations
# Polymorphic Targets:
# - comments (as: :commentable)
#
# == Enums
# - status: { active: "active", maintenance: "maintenance", decommissioned: "decommissioned", obliterated: "obliterated" } (string)
# - cargo_type: { general: "general", refrigerated: "refrigerated", hazardous: "hazardous", livestock: "livestock" } (string)
#
# == Notes
# - Association 'spaceship_crew_members' has N+1 query risk. Consider using includes/preload
# - Association 'crew_members' has N+1 query risk. Consider using includes/preload
# - Association 'missions' has N+1 query risk. Consider using includes/preload
# - Association 'spatial_coordinates' has N+1 query risk. Consider using includes/preload
# - Association 'comments' has N+1 query risk. Consider using includes/preload
# - Column 'name' should probably have NOT NULL constraint
# - Column 'class_type' should probably have NOT NULL constraint
# - Column 'warp_capability' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - Column 'type' should probably have NOT NULL constraint
# - Column 'cargo_capacity' should probably have NOT NULL constraint
# - Column 'cargo_type' should probably have NOT NULL constraint
# - Column 'battle_status' should probably have NOT NULL constraint
# - Boolean column 'warp_capability' should have a default value
# - Status column 'status' should have a default value
# - Status column 'battle_status' should have a default value
# - String column 'name' has no length limit - consider adding one
# - String column 'class_type' has no length limit - consider adding one
# - String column 'status' has no length limit - consider adding one
# - String column 'type' has no length limit - consider adding one
# - String column 'cargo_type' has no length limit - consider adding one
# - String column 'battle_status' has no length limit - consider adding one
# - Column 'class_type' is commonly used in queries - consider adding an index
# - Column 'status' is commonly used in queries - consider adding an index
# - Column 'type' is commonly used in queries - consider adding an index
# - Column 'cargo_type' is commonly used in queries - consider adding an index
# - Column 'battle_status' is commonly used in queries - consider adding an index
# - STI type column 'type' should be indexed
# - STI type column 'type' should have NOT NULL constraint
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
end
