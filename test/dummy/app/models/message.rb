# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "messages"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "content", type = "text", nullable = true },
#   { name = "recipient", type = "string", nullable = true },
#   { name = "priority", type = "integer", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Polymorphic Associations
# Polymorphic Targets:
# - entry (as: :entryable)
#
# == Enums
# - priority: { low: 0, normal: 1, high: 2, urgent: 3 } (integer)
#
# == Notes
# - Column 'content' should probably have NOT NULL constraint
# - Column 'recipient' should probably have NOT NULL constraint
# - Column 'priority' should probably have NOT NULL constraint
# - String column 'recipient' has no length limit - consider adding one
# - Large text column 'content' is frequently queried - consider separate storage
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
