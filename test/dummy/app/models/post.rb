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
# [callbacks]
# after_commit = [{ method = "notify_subscribers" }, { method = "invalidate_cache" }]
# after_rollback = [{ method = "log_failure" }]
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

  # Callbacks
  after_commit :invalidate_cache, on: %i[create update]
  after_commit :notify_subscribers, on: :create
  after_rollback :log_failure

  # Methods
  def publish!
    update!(published: true)
  end

  def unpublish!
    update!(published: false)
  end

  private

  def invalidate_cache
    # Clear cached post data after create/update
    # Rails.cache.delete("post:#{id}")
    # Rails.cache.delete("user:#{user_id}:posts")
  end

  def notify_subscribers
    # Notify subscribers about new post
    # NotificationService.new_post(self)
  end

  def log_failure
    # Log transaction rollback for debugging
    # Rails.logger.error("Post transaction rolled back: #{id}")
  end
end

