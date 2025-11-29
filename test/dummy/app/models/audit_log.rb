# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "audit.audit_logs"
# database_dialect = "PostgreSQL"
# schema = "audit"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "table_name", type = "string", null = false },
#   { name = "record_id", type = "integer", null = false },
#   { name = "action", type = "string", null = false },
#   { name = "user_id", type = "integer", null = false },
#   { name = "changes", type = "jsonb" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# notes = ["changes:NOT_NULL", "table_name:LIMIT", "action:LIMIT"]
# <rails-lens:schema:end>
class AuditLog < ApplicationRecord
  self.table_name = 'audit.audit_logs'

  # Validations
  validates :table_name, presence: true
  validates :record_id, presence: true
  validates :action, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :for_table, ->(table_name) { where(table_name: table_name) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_record, ->(table_name, record_id) { where(table_name: table_name, record_id: record_id) }
end
