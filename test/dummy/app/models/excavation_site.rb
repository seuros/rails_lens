# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "excavation_sites"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "location", type = "string" },
#   { name = "coordinates", type = "string" },
#   { name = "depth", type = "decimal" },
#   { name = "soil_type", type = "string" },
#   { name = "discovered_at", type = "date" },
#   { name = "active", type = "boolean" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "rock_formation", type = "string" },
#   { name = "climate_ancient", type = "string" }
# ]
#
# [enums]
# rock_formation = { morrison = "morrison", hell_creek = "hell_creek", tendaguru = "tendaguru", nemegt = "nemegt", judith_river = "judith_river", solnhofen = "solnhofen", burgess_shale = "burgess_shale" }
# climate_ancient = { tropical = "tropical", subtropical = "subtropical", temperate = "temperate", arid = "arid", coastal = "coastal", swamp = "swamp" }
#
# notes = ["fossil_discoveries:INVERSE_OF", "fossil_discoveries:N_PLUS_ONE", "dinosaurs:N_PLUS_ONE", "name:NOT_NULL", "location:NOT_NULL", "coordinates:NOT_NULL", "depth:NOT_NULL", "soil_type:NOT_NULL", "active:NOT_NULL", "rock_formation:NOT_NULL", "climate_ancient:NOT_NULL", "active:DEFAULT", "name:LIMIT", "location:LIMIT", "coordinates:LIMIT", "soil_type:LIMIT", "soil_type:INDEX"]
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

