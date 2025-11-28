# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "posts"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "title", type = "string", nullable = false },
#   { name = "content", type = "text", nullable = true },
#   { name = "user_id", type = "integer", nullable = false },
#   { name = "published", type = "boolean", nullable = true, default = "false" },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "comments_count", type = "integer", nullable = false, default = "0" }
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
# == Notes
# - Association 'comments' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'user'
# - Column 'content' should probably have NOT NULL constraint
# - Column 'published' should probably have NOT NULL constraint
# - String column 'title' has no length limit - consider adding one
# - Large text column 'content' is frequently queried - consider separate storage
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

