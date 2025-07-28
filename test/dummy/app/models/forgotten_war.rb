# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "forgotten_wars"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "start_year", type = "integer", nullable = true },
#   { name = "end_year", type = "integer", nullable = true },
#   { name = "region", type = "string", nullable = true },
#   { name = "war_type", type = "string", nullable = true },
#   { name = "outcome", type = "string", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Enums
# - war_type: { territorial: "territorial", resource: "resource", extinction_war: "extinction", migration: "migration", climate: "climate" } (string)
# - outcome: { victory: "victory", defeat: "defeat", stalemate: "stalemate", extinction_outcome: "extinction", unknown: "unknown" } (string)
#
# == Notes
# - Column 'name' should probably have NOT NULL constraint
# - Column 'start_year' should probably have NOT NULL constraint
# - Column 'end_year' should probably have NOT NULL constraint
# - Column 'region' should probably have NOT NULL constraint
# - Column 'war_type' should probably have NOT NULL constraint
# - Column 'outcome' should probably have NOT NULL constraint
# - String column 'name' has no length limit - consider adding one
# - String column 'region' has no length limit - consider adding one
# - String column 'war_type' has no length limit - consider adding one
# - String column 'outcome' has no length limit - consider adding one
# - Column 'war_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class ForgottenWar < ApplicationRecord
  # Enums
  enum :war_type, {
    territorial: 'territorial',
    resource: 'resource',
    extinction_war: 'extinction',
    migration: 'migration',
    climate: 'climate'
  }, suffix: true

  enum :outcome, {
    victory: 'victory',
    defeat: 'defeat',
    stalemate: 'stalemate',
    extinction_outcome: 'extinction',
    unknown: 'unknown'
  }, suffix: true

  # Validations
  validates :name, presence: true

  validates :start_year, presence: true, numericality: { only_integer: true }
  validates :end_year, presence: true, numericality: { only_integer: true }
  validates :region, presence: true
  validates :war_type, presence: true
  validates :outcome, presence: true
  validate :end_year_after_start_year

  # Scopes
  scope :by_region, ->(region) { where(region: region) }
  scope :by_type, ->(war_type) { where(war_type: war_type) }
  scope :by_outcome, ->(outcome) { where(outcome: outcome) }
  scope :in_period, ->(start_year, end_year) { where('start_year >= ? AND end_year <= ?', start_year, end_year) }

  private

  def end_year_after_start_year
    return unless start_year.present? && end_year.present?

    errors.add(:end_year, 'must be after start year') if end_year < start_year
  end
end
