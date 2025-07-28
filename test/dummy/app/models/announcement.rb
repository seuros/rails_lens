# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "announcements"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "body", type = "text", nullable = true },
#   { name = "audience", type = "string", nullable = true },
#   { name = "scheduled_at", type = "datetime", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Polymorphic Associations
# Polymorphic Targets:
# - entry (as: :entryable)
#
# == Enums
# - audience: { all_users: "all_users", crew_only: "crew_only", officers_only: "officers_only", command_staff: "command_staff" } (string)
#
# == Notes
# - Column 'body' should probably have NOT NULL constraint
# - Column 'audience' should probably have NOT NULL constraint
# - String column 'audience' has no length limit - consider adding one
# - Large text column 'body' is frequently queried - consider separate storage
# <rails-lens:schema:end>
class Announcement < ApplicationRecord
  # Enums
  enum :audience, {
    all_users: 'all_users',
    crew_only: 'crew_only',
    officers_only: 'officers_only',
    command_staff: 'command_staff'
  }, suffix: true

  # Polymorphic associations
  has_one :entry, as: :entryable, dependent: :destroy

  # Validations
  validates :audience, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
end

