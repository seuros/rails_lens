# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "alerts"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "severity", type = "string", nullable = true },
#   { name = "alert_type", type = "string", nullable = true },
#   { name = "description", type = "text", nullable = true },
#   { name = "resolved", type = "boolean", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Polymorphic Associations
# Polymorphic Targets:
# - entry (as: :entryable)
#
# == Enums
# - severity: { info: "info", warning: "warning", error: "error", critical: "critical" } (string)
# - alert_type: { system: "system", security: "security", maintenance: "maintenance", emergency: "emergency" } (string)
#
# == Notes
# - Column 'severity' should probably have NOT NULL constraint
# - Column 'alert_type' should probably have NOT NULL constraint
# - Column 'description' should probably have NOT NULL constraint
# - Column 'resolved' should probably have NOT NULL constraint
# - Boolean column 'resolved' should have a default value
# - String column 'severity' has no length limit - consider adding one
# - String column 'alert_type' has no length limit - consider adding one
# - Large text column 'description' is frequently queried - consider separate storage
# - Column 'alert_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class Alert < ApplicationRecord
  has_one :entry, as: :entryable, dependent: :destroy

  enum :severity, {
    info: 'info',
    warning: 'warning',
    error: 'error',
    critical: 'critical'
  }

  enum :alert_type, {
    system: 'system',
    security: 'security',
    maintenance: 'maintenance',
    emergency: 'emergency'
  }

  validates :severity, presence: true
  validates :alert_type, presence: true
  validates :description, presence: true

  scope :unresolved, -> { where(resolved: [false, nil]) }

  scope :critical_alerts, -> { where(severity: 'critical') }
end

