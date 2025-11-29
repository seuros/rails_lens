# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "forgotten_wars"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "start_year", type = "integer" },
#   { name = "end_year", type = "integer" },
#   { name = "region", type = "string" },
#   { name = "war_type", type = "string" },
#   { name = "outcome", type = "string" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [enums]
# war_type = { territorial = "territorial", resource = "resource", extinction_war = "extinction", migration = "migration", climate = "climate" }
# outcome = { victory = "victory", defeat = "defeat", stalemate = "stalemate", extinction_outcome = "extinction", unknown = "unknown" }
#
# notes = ["name:NOT_NULL", "start_year:NOT_NULL", "end_year:NOT_NULL", "region:NOT_NULL", "war_type:NOT_NULL", "outcome:NOT_NULL", "name:LIMIT", "region:LIMIT", "war_type:LIMIT", "outcome:LIMIT", "war_type:INDEX"]
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
