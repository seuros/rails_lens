# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "dinosaurs"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "species", type = "string", nullable = true },
#   { name = "period", type = "string", nullable = true },
#   { name = "diet", type = "string", nullable = true },
#   { name = "length", type = "decimal", nullable = true },
#   { name = "weight", type = "decimal", nullable = true },
#   { name = "discovered_at", type = "date", nullable = true },
#   { name = "extinction_date", type = "date", nullable = true },
#   { name = "fossil_count", type = "integer", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Enums
# - period: { triassic: "triassic", jurassic: "jurassic", cretaceous: "cretaceous" } (string)
# - diet: { herbivore: "herbivore", carnivore: "carnivore", omnivore: "omnivore", piscivore: "piscivore" } (string)
#
# == Notes
# - Association 'fossil_discoveries' should specify inverse_of
# - Association 'fossil_discoveries' has N+1 query risk. Consider using includes/preload
# - Column 'name' should probably have NOT NULL constraint
# - Column 'species' should probably have NOT NULL constraint
# - Column 'period' should probably have NOT NULL constraint
# - Column 'diet' should probably have NOT NULL constraint
# - Column 'length' should probably have NOT NULL constraint
# - Column 'weight' should probably have NOT NULL constraint
# - Column 'fossil_count' should probably have NOT NULL constraint
# - String column 'name' has no length limit - consider adding one
# - String column 'species' has no length limit - consider adding one
# - String column 'period' has no length limit - consider adding one
# - String column 'diet' has no length limit - consider adding one
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

