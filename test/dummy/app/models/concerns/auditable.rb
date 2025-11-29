# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :audit_creation
    after_update :audit_update
    after_destroy :audit_destruction
  end

  private

  def audit_creation
    # Record creation event
    # AuditLog.record(self, :created, current_user)
  end

  def audit_update
    # Record update with changed attributes
    # AuditLog.record(self, :updated, saved_changes)
  end

  def audit_destruction
    # Record deletion event
    # AuditLog.record(self, :destroyed, attributes)
  end
end
