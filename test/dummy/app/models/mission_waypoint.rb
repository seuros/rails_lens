# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "mission_waypoints"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "mission_id", type = "integer", null = false },
#   { name = "sequence", type = "integer" },
#   { name = "coordinates", type = "string" },
#   { name = "eta", type = "datetime" },
#   { name = "notes", type = "text" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "waypoint_type", type = "string" },
#   { name = "status", type = "string" }
# ]
#
# indexes = [
#   { name = "index_mission_waypoints_on_mission_id", columns = ["mission_id"] }
# ]
#
# foreign_keys = [
#   { column = "mission_id", references_table = "missions", references_column = "id", name = "fk_rails_e40edbce49" }
# ]
#
# [enums]
# waypoint_type = { start = "start", checkpoint = "checkpoint", destination = "destination", emergency = "emergency" }
# status = { pending = "pending", reached = "reached", skipped = "skipped" }
#
# notes = ["mission:INVERSE_OF", "sequence:NOT_NULL", "coordinates:NOT_NULL", "eta:NOT_NULL", "notes:NOT_NULL", "waypoint_type:NOT_NULL", "status:NOT_NULL", "status:DEFAULT", "coordinates:LIMIT", "waypoint_type:INDEX", "status:INDEX", "notes:STORAGE"]
# <rails-lens:schema:end>
class MissionWaypoint < ApplicationRecord
  # Enums
  enum :waypoint_type, {
    start: 'start',
    checkpoint: 'checkpoint',
    destination: 'destination',
    emergency: 'emergency'
  }, suffix: true

  enum :status, {
    pending: 'pending',
    reached: 'reached',
    skipped: 'skipped'
  }, suffix: true

  # Associations
  belongs_to :mission

  # Validations
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :coordinates, presence: true
  validates :waypoint_type, presence: true
  validates :status, presence: true

  # Scopes
  scope :ordered, -> { order(:sequence) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(waypoint_type) { where(waypoint_type: waypoint_type) }
  scope :pending, -> { where(status: :pending) }

  scope :reached, -> { where(status: :reached) }

  # Callbacks
  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status ||= :pending
  end
end

