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
# [callbacks]
# before_save = [{ method = "set_severity_timestamp" }, { method = "notify_if_critical" }, { method = "log_alert_change" }]
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

  # Callbacks - multiple on same hook (order matters)
  before_save :set_severity_timestamp
  before_save :notify_if_critical
  before_save :log_alert_change

  private

  def set_severity_timestamp
    self.severity_changed_at = Time.current if severity_changed?
  end

  def notify_if_critical
    AlertNotifier.critical_alert(self) if severity == 'critical' && severity_changed?
  end

  def log_alert_change
    Rails.logger.info("Alert #{id}: #{changes}")
  end
end

