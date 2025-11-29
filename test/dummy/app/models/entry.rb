# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "entries"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "title", type = "string" },
#   { name = "published", type = "boolean" },
#   { name = "entryable_type", type = "string" },
#   { name = "entryable_id", type = "integer" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [polymorphic]
# references = [{ name = "entryable", type_col = "entryable_type", id_col = "entryable_id" }]
#
# [delegated_type]
# type_column = "entryable_type"
# id_column = "entryable_id"
# types = ["Message", "Announcement", "Alert"]
#
# notes = ["entryable:POLY_INDEX", "title:NOT_NULL", "published:NOT_NULL", "entryable_type:NOT_NULL", "published:DEFAULT", "title:LIMIT", "entryable_type:LIMIT", "entryable_type:INDEX"]
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

