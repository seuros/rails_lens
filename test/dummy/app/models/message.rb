# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "messages"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "content", type = "text" },
#   { name = "recipient", type = "string" },
#   { name = "priority", type = "integer" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [polymorphic]
# targets = [{ name = "entry", as = "entryable" }]
#
# [enums]
# priority = { low = 0, normal = 1, high = 2, urgent = 3 }
#
# [callbacks]
# before_validation = [{ method = "set_default_priority" }]
#
# notes = ["content:NOT_NULL", "recipient:NOT_NULL", "priority:NOT_NULL", "recipient:LIMIT", "content:STORAGE"]
# <rails-lens:schema:end>
class Message < ApplicationRecord
  # Enums
  enum :priority, {
    low: 0,
    normal: 1,
    high: 2,
    urgent: 3
  }, suffix: true

  # Polymorphic associations
  has_one :entry, as: :entryable, dependent: :destroy

  # Validations
  validates :content, presence: true
  validates :recipient, presence: true
  validates :priority, presence: true

  # Scopes
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :urgent_and_high, -> { where(priority: %i[urgent high]) }

  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_default_priority, on: :create

  private

  def set_default_priority
    self.priority ||= :normal
  end
end
