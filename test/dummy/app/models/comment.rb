# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "comments"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "body", type = "text", null = false },
#   { name = "user_id", type = "integer", null = false },
#   { name = "post_id", type = "integer" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "commentable_type", type = "string" },
#   { name = "commentable_id", type = "integer" }
# ]
#
# indexes = [
#   { name = "index_comments_on_commentable", columns = ["commentable_type", "commentable_id"] },
#   { name = "index_comments_on_post_id", columns = ["post_id"] },
#   { name = "index_comments_on_user_id", columns = ["user_id"] }
# ]
#
# foreign_keys = [
#   { column = "user_id", references_table = "users", references_column = "id", name = "fk_rails_03de2dc08c" },
#   { column = "post_id", references_table = "posts", references_column = "id", name = "fk_rails_2fd19c0db7" }
# ]
#
# triggers = [
#   { name = "increment_posts_comments_count", event = "INSERT", timing = "AFTER", function = "update_posts_comments_count", for_each = "ROW", condition = "(new.post_id IS NOT NULL)" },
#   { name = "decrement_posts_comments_count", event = "DELETE", timing = "AFTER", function = "update_posts_comments_count", for_each = "ROW", condition = "(old.post_id IS NOT NULL)" },
#   { name = "update_posts_comments_count_on_reassign", event = "UPDATE", timing = "AFTER", function = "update_posts_comments_count", for_each = "ROW", condition = "(old.post_id IS DISTINCT FROM new.post_id)" }
# ]
#
# [polymorphic]
# references = [{ name = "commentable", type_col = "commentable_type", id_col = "commentable_id" }]
#
# notes = ["user:COUNTER_CACHE", "post:COUNTER_CACHE", "commentable_type:NOT_NULL", "commentable_type:LIMIT", "body:STORAGE"]
# <rails-lens:schema:end>
class Comment < ApplicationRecord
  # Associations
  belongs_to :user, inverse_of: :comments
  belongs_to :post, optional: true, inverse_of: :comments

  # Polymorphic association
  belongs_to :commentable, polymorphic: true, optional: true

  # Validations
  validates :body, presence: true
  validate :has_parent_object

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  private

  def has_parent_object
    return unless post.blank? && commentable.blank?

    errors.add(:base, 'Comment must belong to either a post or commentable object')
  end
end

