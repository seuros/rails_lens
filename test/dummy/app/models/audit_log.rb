# frozen_string_literal: true
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
