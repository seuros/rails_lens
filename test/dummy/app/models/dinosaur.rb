# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "dinosaurs"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "species", type = "string" },
#   { name = "period", type = "string" },
#   { name = "diet", type = "string" },
#   { name = "length", type = "decimal" },
#   { name = "weight", type = "decimal" },
#   { name = "discovered_at", type = "date" },
#   { name = "extinction_date", type = "date" },
#   { name = "fossil_count", type = "integer" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [enums]
# period = { triassic = "triassic", jurassic = "jurassic", cretaceous = "cretaceous" }
# diet = { herbivore = "herbivore", carnivore = "carnivore", omnivore = "omnivore", piscivore = "piscivore" }
#
# notes = ["fossil_discoveries:INVERSE_OF", "fossil_discoveries:N_PLUS_ONE", "name:NOT_NULL", "species:NOT_NULL", "period:NOT_NULL", "diet:NOT_NULL", "length:NOT_NULL", "weight:NOT_NULL", "fossil_count:NOT_NULL", "name:LIMIT", "species:LIMIT", "period:LIMIT", "diet:LIMIT"]
# <rails-lens:schema:end>
class Dinosaur < PrehistoricRecord
  # Enums
  enum :period, {
    triassic: 'triassic',
    jurassic: 'jurassic',
    cretaceous: 'cretaceous'
  }, suffix: true

  enum :diet, {
    herbivore: 'herbivore',
    carnivore: 'carnivore',
    omnivore: 'omnivore',
    piscivore: 'piscivore'
  }, suffix: true

  # Associations
  has_many :fossil_discoveries, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :species, presence: true
  validates :period, presence: true
  validates :diet, presence: true

  validates :length, presence: true, numericality: { greater_than: 0 }
  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :fossil_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :by_period, ->(period) { where(period: period) }
  scope :by_diet, ->(diet) { where(diet: diet) }
  scope :discovered_after, ->(date) { where('discovered_at > ?', date) }
end

