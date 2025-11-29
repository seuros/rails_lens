# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "missions"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "objective", type = "text" },
#   { name = "status", type = "string" },
#   { name = "priority", type = "integer" },
#   { name = "start_date", type = "date" },
#   { name = "end_date", type = "date" },
#   { name = "estimated_duration", type = "interval" },
#   { name = "classification_level", type = "string" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "classification", type = "string" }
# ]
#
# [enums]
# status = { planned = "planned", active = "active", completed = "completed", failed = "failed", aborted = "aborted" }
# classification = { exploration = "exploration", diplomatic = "diplomatic", military = "military", scientific = "scientific", rescue = "rescue" }
#
# [callbacks]
# around_save = [{ method = "log_mission_changes" }]
# around_destroy = [{ method = "archive_before_destroy" }]
#
# notes = ["spaceship_id:INDEX", "spaceship_id:FK_CONSTRAINT", "mission_waypoints:N_PLUS_ONE", "spaceship:COUNTER_CACHE", "name:NOT_NULL", "objective:NOT_NULL", "status:NOT_NULL", "priority:NOT_NULL", "estimated_duration:NOT_NULL", "classification_level:NOT_NULL", "classification:NOT_NULL", "status:DEFAULT", "name:LIMIT", "status:LIMIT", "classification_level:LIMIT", "status:INDEX", "objective:STORAGE"]
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

  # Callbacks
  around_save :log_mission_changes
  around_destroy :archive_before_destroy

  private

  def log_mission_changes
    # Log state before save
    # Rails.logger.info("Mission #{id} before: #{changes}")
    yield
    # Log state after save
    # Rails.logger.info("Mission #{id} after: #{saved_changes}")
  end

  def archive_before_destroy
    # Archive mission data before destruction
    # MissionArchive.create!(mission_data: attributes)
    yield
    # Clean up related archives if needed
    # MissionArchive.cleanup_orphans
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    return unless end_date < start_date

    errors.add(:end_date, 'must be after the start date')
  end
end
