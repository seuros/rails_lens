# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "audit.audit_logs"
# database_dialect = "PostgreSQL"
# schema = "audit"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "table_name", type = "string", nullable = false },
#   { name = "record_id", type = "integer", nullable = false },
#   { name = "action", type = "string", nullable = false },
#   { name = "user_id", type = "integer", nullable = false },
#   { name = "changes", type = "jsonb", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Notes
# - Column 'changes' should probably have NOT NULL constraint
# - String column 'table_name' has no length limit - consider adding one
# - String column 'action' has no length limit - consider adding one
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
