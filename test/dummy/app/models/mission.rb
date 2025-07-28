# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "missions"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "objective", type = "text", nullable = true },
#   { name = "status", type = "string", nullable = true },
#   { name = "priority", type = "integer", nullable = true },
#   { name = "start_date", type = "date", nullable = true },
#   { name = "end_date", type = "date", nullable = true },
#   { name = "estimated_duration", type = "interval", nullable = true },
#   { name = "classification_level", type = "string", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "classification", type = "string", nullable = true }
# ]
#
# == Enums
# - status: { planned: "planned", active: "active", completed: "completed", failed: "failed", aborted: "aborted" } (string)
# - classification: { exploration: "exploration", diplomatic: "diplomatic", military: "military", scientific: "scientific", rescue: "rescue" } (string)
#
# == Notes
# - Missing index on foreign key 'spaceship_id'
# - Missing foreign key constraint on 'spaceship_id' referencing 'spaceships'
# - Association 'mission_waypoints' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'spaceship'
# - Column 'name' should probably have NOT NULL constraint
# - Column 'objective' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - Column 'priority' should probably have NOT NULL constraint
# - Column 'estimated_duration' should probably have NOT NULL constraint
# - Column 'classification_level' should probably have NOT NULL constraint
# - Column 'classification' should probably have NOT NULL constraint
# - Status column 'status' should have a default value
# - String column 'name' has no length limit - consider adding one
# - String column 'status' has no length limit - consider adding one
# - String column 'classification_level' has no length limit - consider adding one
# - Column 'status' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class Mission < ApplicationRecord
  # Enums
  enum :status, {
    planned: 'planned',
    active: 'active',
    completed: 'completed',
    failed: 'failed',
    aborted: 'aborted'
  }, suffix: true

  enum :classification, {
    exploration: 'exploration',
    diplomatic: 'diplomatic',
    military: 'military',
    scientific: 'scientific',
    rescue: 'rescue'
  }, suffix: true

  # Associations
  belongs_to :spaceship, inverse_of: :missions
  has_many :mission_waypoints, dependent: :destroy, inverse_of: :mission

  # Validations
  validates :name, presence: true
  validates :objective, presence: true
  validates :status, presence: true
  validates :priority, presence: true, numericality: { in: 1..10 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :classification_level, presence: true
  validates :classification, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_classification, ->(classification) { where(classification: classification) }
  scope :high_priority, -> { where('priority >= ?', 8) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    return unless end_date < start_date

    errors.add(:end_date, 'must be after the start date')
  end
end
