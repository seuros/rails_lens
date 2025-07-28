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
# Known Subclasses: CargoVessel, StarfleetBattleCruiser
# Base Class: Yes
#
# == Polymorphic Associations
# Polymorphic Targets:
# - comments (as: :commentable)
#
# == Enums
# - status: { active: "active", maintenance: "maintenance", decommissioned: "decommissioned", obliterated: "obliterated" } (string)
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
class Spaceship < ApplicationRecord
  # Enums
  enum :status, {
    active: 'active',
    maintenance: 'maintenance',
    decommissioned: 'decommissioned',
    obliterated: 'obliterated'
  }, suffix: true

  # Associations
  has_many :spaceship_crew_members, dependent: :destroy, inverse_of: :spaceship
  has_many :crew_members, through: :spaceship_crew_members
  has_many :missions, dependent: :destroy, inverse_of: :spaceship
  has_many :spatial_coordinates, dependent: :destroy, inverse_of: :spaceship
  has_many :comments, as: :commentable, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :class_type, presence: true
  validates :status, presence: true
  validates :warp_capability, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :with_warp, -> { where(warp_capability: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_class_type, ->(class_type) { where(class_type: class_type) }

  # Callbacks
  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.warp_capability = false if warp_capability.nil?
    self.status ||= 'active'
  end
end

