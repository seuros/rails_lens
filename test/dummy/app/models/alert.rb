# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "alerts"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "severity", type = "string" },
#   { name = "alert_type", type = "string" },
#   { name = "description", type = "text" },
#   { name = "resolved", type = "boolean" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [polymorphic]
# targets = [{ name = "entry", as = "entryable" }]
#
# [enums]
# severity = { info = "info", warning = "warning", error = "error", critical = "critical" }
# alert_type = { system = "system", security = "security", maintenance = "maintenance", emergency = "emergency" }
#
# notes = ["severity:NOT_NULL", "alert_type:NOT_NULL", "description:NOT_NULL", "resolved:NOT_NULL", "resolved:DEFAULT", "severity:LIMIT", "alert_type:LIMIT", "alert_type:INDEX", "description:STORAGE"]
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

