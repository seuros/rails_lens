# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "home_planets"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "galaxy", type = "string" },
#   { name = "coordinates", type = "st_geometry" },
#   { name = "habitability_score", type = "decimal" },
#   { name = "climate_type", type = "string" },
#   { name = "population", type = "integer" },
#   { name = "established_at", type = "date" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "classification", type = "string" },
#   { name = "hierarchy_type", type = "string" }
# ]
#
# indexes = [
#   { name = "index_home_planets_on_coordinates", columns = ["coordinates"] }
# ]
#
# [extensions]
# [closure_tree]
# parent_column = "parent_id"
# hierarchy_table = "home_planet_hierarchies"
# order_column = "name"
#
# [enums]
# classification = { class_m = "class_m", class_k = "class_k", class_l = "class_l", class_y = "class_y", artificial = "artificial" }
# hierarchy_type = { galaxy = "galaxy", quadrant = "quadrant", sector = "sector", system = "system", planet = "planet", moon = "moon", station = "station" }
#
# [callbacks]
# before_save = [{ method = "_ct_before_save" }]
# after_save = [{ method = "_ct_after_save" }]
# before_destroy = [{ method = "_ct_before_destroy" }]
#
# notes = ["parent_id:INDEX", "parent_id:FK_CONSTRAINT", "ancestor_hierarchies:INVERSE_OF", "descendant_hierarchies:INVERSE_OF", "children:N_PLUS_ONE", "ancestor_hierarchies:N_PLUS_ONE", "self_and_ancestors:N_PLUS_ONE", "descendant_hierarchies:N_PLUS_ONE", "self_and_descendants:N_PLUS_ONE", "crew_members:N_PLUS_ONE", "parent:COUNTER_CACHE", "name:NOT_NULL", "galaxy:NOT_NULL", "coordinates:NOT_NULL", "habitability_score:NOT_NULL", "climate_type:NOT_NULL", "population:NOT_NULL", "classification:NOT_NULL", "hierarchy_type:NOT_NULL", "name:LIMIT", "galaxy:LIMIT", "climate_type:LIMIT", "climate_type:INDEX", "hierarchy_type:INDEX", "home_planet_hierarchies:COMP_INDEX", "generations:INDEX", "children:COUNTER_CACHE"]
# <rails-lens:schema:end>
class HomePlanet < ApplicationRecord
  # ClosureTree for hierarchical structure
  has_closure_tree order: 'name'

  # Enums
  enum :classification, {
    class_m: 'class_m',
    class_k: 'class_k',
    class_l: 'class_l',
    class_y: 'class_y',
    artificial: 'artificial'
  }, suffix: true

  enum :hierarchy_type, {
    galaxy: 'galaxy',
    quadrant: 'quadrant',
    sector: 'sector',
    system: 'system',
    planet: 'planet',
    moon: 'moon',
    station: 'station'
  }, suffix: true

  # Associations
  has_many :crew_members, inverse_of: :home_planet

  # Validations
  validates :name, presence: true
  validates :galaxy, presence: true
  validates :habitability_score, presence: true,
                                 numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :climate_type, presence: true
  validates :population, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :classification, presence: true
  validates :hierarchy_type, presence: true

  # Scopes
  scope :habitable, -> { where('habitability_score >= ?', 50) }
  scope :by_classification, ->(classification) { where(classification: classification) }
  scope :by_hierarchy_type, ->(type) { where(hierarchy_type: type) }
end

