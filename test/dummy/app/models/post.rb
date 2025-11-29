# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "posts"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "title", type = "string", null = false },
#   { name = "content", type = "text" },
#   { name = "user_id", type = "integer", null = false },
#   { name = "published", type = "boolean", default = "false" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "comments_count", type = "integer", null = false, default = "0" }
# ]
#
# indexes = [
#   { name = "index_posts_on_published", columns = ["published"] },
#   { name = "index_posts_on_user_id", columns = ["user_id"] }
# ]
#
# foreign_keys = [
#   { column = "user_id", references_table = "users", references_column = "id", name = "fk_rails_5b5ddfd518" }
# ]
#
# notes = ["comments:N_PLUS_ONE", "user:COUNTER_CACHE", "content:NOT_NULL", "published:NOT_NULL", "title:LIMIT", "content:STORAGE"]
# <rails-lens:schema:end>
# Test annotation
class Post < ApplicationRecord
  # Associations
  belongs_to :user, inverse_of: :posts
  has_many :comments, dependent: :destroy, inverse_of: :post

  # Validations
  validates :title, presence: true
  validates :content, presence: true

  # Scopes
  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  # Methods
  def publish!
    update!(published: true)
  end

  def unpublish!
    update!(published: false)
  end

end

