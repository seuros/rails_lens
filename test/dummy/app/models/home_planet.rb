# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "home_planets"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "galaxy", type = "string", nullable = true },
#   { name = "coordinates", type = "st_geometry", nullable = true },
#   { name = "habitability_score", type = "decimal", nullable = true },
#   { name = "climate_type", type = "string", nullable = true },
#   { name = "population", type = "integer", nullable = true },
#   { name = "established_at", type = "date", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "classification", type = "string", nullable = true },
#   { name = "hierarchy_type", type = "string", nullable = true }
# ]
#
# indexes = [
#   { name = "index_home_planets_on_coordinates", columns = ["coordinates"] }
# ]
#
# == Extensions
# == Hierarchy (ClosureTree)
# Parent Column: parent_id
# Hierarchy Table: home_planet_hierarchies
# Order Column: name
#
# == Enums
# - classification: { class_m: "class_m", class_k: "class_k", class_l: "class_l", class_y: "class_y", artificial: "artificial" } (string)
# - hierarchy_type: { galaxy: "galaxy", quadrant: "quadrant", sector: "sector", system: "system", planet: "planet", moon: "moon", station: "station" } (string)
#
# == Notes
# - Missing index on foreign key 'parent_id'
# - Missing foreign key constraint on 'parent_id' referencing 'home_planets'
# - Association 'ancestor_hierarchies' should specify inverse_of
# - Association 'descendant_hierarchies' should specify inverse_of
# - Association 'children' has N+1 query risk. Consider using includes/preload
# - Association 'ancestor_hierarchies' has N+1 query risk. Consider using includes/preload
# - Association 'self_and_ancestors' has N+1 query risk. Consider using includes/preload
# - Association 'descendant_hierarchies' has N+1 query risk. Consider using includes/preload
# - Association 'self_and_descendants' has N+1 query risk. Consider using includes/preload
# - Association 'crew_members' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'parent'
# - Column 'name' should probably have NOT NULL constraint
# - Column 'galaxy' should probably have NOT NULL constraint
# - Column 'coordinates' should probably have NOT NULL constraint
# - Column 'habitability_score' should probably have NOT NULL constraint
# - Column 'climate_type' should probably have NOT NULL constraint
# - Column 'population' should probably have NOT NULL constraint
# - Column 'classification' should probably have NOT NULL constraint
# - Column 'hierarchy_type' should probably have NOT NULL constraint
# - String column 'name' has no length limit - consider adding one
# - String column 'galaxy' has no length limit - consider adding one
# - String column 'climate_type' has no length limit - consider adding one
# - Column 'climate_type' is commonly used in queries - consider adding an index
# - Column 'hierarchy_type' is commonly used in queries - consider adding an index
# - Missing index on parent column 'parent_id'
# - Hierarchy table 'home_planet_hierarchies' needs compound index on (ancestor_id, descendant_id)
# - Consider adding index on generations column in hierarchy table for depth queries
# - Consider adding counter cache 'children_count' for children count
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

