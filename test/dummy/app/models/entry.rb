# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "entries"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "title", type = "string", nullable = true },
#   { name = "published", type = "boolean", nullable = true },
#   { name = "entryable_type", type = "string", nullable = true },
#   { name = "entryable_id", type = "integer", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Polymorphic Associations
# Polymorphic References:
# - entryable (entryable_type/entryable_id)
#
# == Delegated Type
# Type Column: entryable_type
# ID Column: entryable_id
# Types: Message, Announcement, Alert
#
# == Notes
# - Missing composite index on polymorphic association 'entryable' columns [entryable_type, entryable_id]
# - Column 'title' should probably have NOT NULL constraint
# - Column 'published' should probably have NOT NULL constraint
# - Column 'entryable_type' should probably have NOT NULL constraint
# - Boolean column 'published' should have a default value
# - String column 'title' has no length limit - consider adding one
# - String column 'entryable_type' has no length limit - consider adding one
# - Column 'entryable_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class Entry < ApplicationRecord
  # Delegated type
  delegated_type :entryable, types: %w[Message Announcement Alert]

  # Validations
  validates :title, presence: true
  validates :entryable_type, presence: true

  # Scopes
  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_default_published, on: :create

  private

  def set_default_published
    self.published = false if published.nil?
  end
end

