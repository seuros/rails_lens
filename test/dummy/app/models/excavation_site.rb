# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "excavation_sites"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "location", type = "string", nullable = true },
#   { name = "coordinates", type = "string", nullable = true },
#   { name = "depth", type = "decimal", nullable = true },
#   { name = "soil_type", type = "string", nullable = true },
#   { name = "discovered_at", type = "date", nullable = true },
#   { name = "active", type = "boolean", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "rock_formation", type = "string", nullable = true },
#   { name = "climate_ancient", type = "string", nullable = true }
# ]
#
# == Enums
# - rock_formation: { morrison: "morrison", hell_creek: "hell_creek", tendaguru: "tendaguru", nemegt: "nemegt", judith_river: "judith_river", solnhofen: "solnhofen", burgess_shale: "burgess_shale" } (string)
# - climate_ancient: { tropical: "tropical", subtropical: "subtropical", temperate: "temperate", arid: "arid", coastal: "coastal", swamp: "swamp" } (string)
#
# == Notes
# - Association 'fossil_discoveries' should specify inverse_of
# - Association 'fossil_discoveries' has N+1 query risk. Consider using includes/preload
# - Association 'dinosaurs' has N+1 query risk. Consider using includes/preload
# - Column 'name' should probably have NOT NULL constraint
# - Column 'location' should probably have NOT NULL constraint
# - Column 'coordinates' should probably have NOT NULL constraint
# - Column 'depth' should probably have NOT NULL constraint
# - Column 'soil_type' should probably have NOT NULL constraint
# - Column 'active' should probably have NOT NULL constraint
# - Column 'rock_formation' should probably have NOT NULL constraint
# - Column 'climate_ancient' should probably have NOT NULL constraint
# - Boolean column 'active' should have a default value
# - String column 'name' has no length limit - consider adding one
# - String column 'location' has no length limit - consider adding one
# - String column 'coordinates' has no length limit - consider adding one
# - String column 'soil_type' has no length limit - consider adding one
# - Column 'soil_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class ExcavationSite < PrehistoricRecord
  # Enums
  enum :rock_formation, {
    morrison: 'morrison',
    hell_creek: 'hell_creek',
    tendaguru: 'tendaguru',
    nemegt: 'nemegt',
    judith_river: 'judith_river',
    solnhofen: 'solnhofen',
    burgess_shale: 'burgess_shale'
  }, suffix: true

  enum :climate_ancient, {
    tropical: 'tropical',
    subtropical: 'subtropical',
    temperate: 'temperate',
    arid: 'arid',
    coastal: 'coastal',
    swamp: 'swamp'
  }, prefix: :ancient

  # Associations
  has_many :fossil_discoveries, dependent: :destroy

  has_many :dinosaurs, through: :fossil_discoveries

  # Validations
  validates :name, presence: true
  validates :location, presence: true
  validates :coordinates, presence: true
  validates :depth, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :soil_type, presence: true
  validates :rock_formation, presence: true
  validates :climate_ancient, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_formation, ->(formation) { where(rock_formation: formation) }
  scope :discovered_after, ->(date) { where('discovered_at > ?', date) }
end

