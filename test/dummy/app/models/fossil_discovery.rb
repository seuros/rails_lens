# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "fossil_discoveries"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "dinosaur_id", type = "integer", null = false },
#   { name = "excavation_site_id", type = "integer", null = false },
#   { name = "discovered_at", type = "date" },
#   { name = "condition", type = "string" },
#   { name = "completeness", type = "decimal" },
#   { name = "notes", type = "text" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "preservation_quality", type = "string" },
#   { name = "fossil_type", type = "string" }
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
# [enums]
# preservation_quality = { excellent = "excellent", good = "good", fair = "fair", poor = "poor", fragmentary = "fragmentary" }
# fossil_type = { skeleton = "skeleton", skull = "skull", teeth = "teeth", tracks = "tracks", eggs = "eggs", coprolite = "coprolite", skin_impression = "skin_impression" }
#
# [callbacks]
# before_validation = [{ method = "normalize_condition" }, { method = "set_discovered_date" }]
# after_validation = [{ method = "log_validation_errors", if = ["proc"] }]
# after_create = [{ method = "increment_dinosaur_fossil_count" }]
# after_destroy = [{ method = "decrement_dinosaur_fossil_count" }]
#
# notes = ["dinosaur:COUNTER_CACHE", "excavation_site:COUNTER_CACHE", "condition:NOT_NULL", "completeness:NOT_NULL", "notes:NOT_NULL", "preservation_quality:NOT_NULL", "fossil_type:NOT_NULL", "condition:LIMIT", "fossil_type:INDEX", "notes:STORAGE"]
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

  # Callbacks - Validation callbacks
  before_validation :normalize_condition
  before_validation :set_discovered_date, on: :create
  after_validation :log_validation_errors, if: -> { errors.any? }

  after_create :increment_dinosaur_fossil_count
  after_destroy :decrement_dinosaur_fossil_count

  private

  def normalize_condition
    self.condition = condition.to_s.strip.downcase if condition.present?
  end

  def set_discovered_date
    self.discovered_at ||= Date.current
  end

  def log_validation_errors
    Rails.logger.warn("FossilDiscovery validation failed: #{errors.full_messages.join(', ')}")
  end

  def increment_dinosaur_fossil_count
    dinosaur.increment!(:fossil_count)
  end

  def decrement_dinosaur_fossil_count
    dinosaur.decrement!(:fossil_count)
  end
end

