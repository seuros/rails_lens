# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "announcements"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "body", type = "text" },
#   { name = "audience", type = "string" },
#   { name = "scheduled_at", type = "datetime" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [polymorphic]
# targets = [{ name = "entry", as = "entryable" }]
#
# [enums]
# audience = { all_users = "all_users", crew_only = "crew_only", officers_only = "officers_only", command_staff = "command_staff" }
#
# notes = ["body:NOT_NULL", "audience:NOT_NULL", "audience:LIMIT", "body:STORAGE"]
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

