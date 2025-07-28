# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "fossil_discoveries"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "dinosaur_id", type = "integer", nullable = false },
#   { name = "excavation_site_id", type = "integer", nullable = false },
#   { name = "discovered_at", type = "date", nullable = true },
#   { name = "condition", type = "string", nullable = true },
#   { name = "completeness", type = "decimal", nullable = true },
#   { name = "notes", type = "text", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "preservation_quality", type = "string", nullable = true },
#   { name = "fossil_type", type = "string", nullable = true }
# ]
#
# indexes = [
#   { name = "index_fossil_discoveries_on_excavation_site_id", columns = ["excavation_site_id"] },
#   { name = "index_fossil_discoveries_on_dinosaur_id", columns = ["dinosaur_id"] }
# ]
#
# foreign_keys = [
#   { column = "excavation_site_id", references_table = "excavation_sites", references_column = "id" },
#   { column = "dinosaur_id", references_table = "dinosaurs", references_column = "id" }
# ]
#
# == Enums
# - preservation_quality: { excellent: "excellent", good: "good", fair: "fair", poor: "poor", fragmentary: "fragmentary" } (string)
# - fossil_type: { skeleton: "skeleton", skull: "skull", teeth: "teeth", tracks: "tracks", eggs: "eggs", coprolite: "coprolite", skin_impression: "skin_impression" } (string)
#
# == Notes
# - Consider adding counter cache for 'dinosaur'
# - Consider adding counter cache for 'excavation_site'
# - Column 'condition' should probably have NOT NULL constraint
# - Column 'completeness' should probably have NOT NULL constraint
# - Column 'notes' should probably have NOT NULL constraint
# - Column 'preservation_quality' should probably have NOT NULL constraint
# - Column 'fossil_type' should probably have NOT NULL constraint
# - String column 'condition' has no length limit - consider adding one
# - Column 'fossil_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class FossilDiscovery < PrehistoricRecord
  # Enums
  enum :preservation_quality, {
    excellent: 'excellent',
    good: 'good',
    fair: 'fair',
    poor: 'poor',
    fragmentary: 'fragmentary'
  }, suffix: true

  enum :fossil_type, {
    skeleton: 'skeleton',
    skull: 'skull',
    teeth: 'teeth',
    tracks: 'tracks',
    eggs: 'eggs',
    coprolite: 'coprolite',
    skin_impression: 'skin_impression'
  }, suffix: true

  # Associations
  belongs_to :dinosaur, inverse_of: :fossil_discoveries
  belongs_to :excavation_site, inverse_of: :fossil_discoveries

  # Validations
  validates :condition, presence: true
  validates :completeness, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :preservation_quality, presence: true
  validates :fossil_type, presence: true

  # Scopes
  scope :recent, -> { order(discovered_at: :desc) }

  scope :by_quality, ->(quality) { where(preservation_quality: quality) }
  scope :by_type, ->(type) { where(fossil_type: type) }
  scope :complete, -> { where('completeness >= ?', 90) }
end

