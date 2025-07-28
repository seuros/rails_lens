# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "mission_waypoints"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "mission_id", type = "integer", nullable = false },
#   { name = "sequence", type = "integer", nullable = true },
#   { name = "coordinates", type = "string", nullable = true },
#   { name = "eta", type = "datetime", nullable = true },
#   { name = "notes", type = "text", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "waypoint_type", type = "string", nullable = true },
#   { name = "status", type = "string", nullable = true }
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
# == Enums
# - waypoint_type: { start: "start", checkpoint: "checkpoint", destination: "destination", emergency: "emergency" } (string)
# - status: { pending: "pending", reached: "reached", skipped: "skipped" } (string)
#
# == Notes
# - Association 'mission' should specify inverse_of
# - Column 'sequence' should probably have NOT NULL constraint
# - Column 'coordinates' should probably have NOT NULL constraint
# - Column 'eta' should probably have NOT NULL constraint
# - Column 'notes' should probably have NOT NULL constraint
# - Column 'waypoint_type' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - Status column 'status' should have a default value
# - String column 'coordinates' has no length limit - consider adding one
# - Column 'waypoint_type' is commonly used in queries - consider adding an index
# - Column 'status' is commonly used in queries - consider adding an index
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

