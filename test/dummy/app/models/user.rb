# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "users"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "email", type = "string", nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "status", type = "string", nullable = true, default = "active" },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# indexes = [
#   { name = "index_users_on_email", columns = ["email"], unique = true }
# ]
#
# == Notes
# - Association 'posts' has N+1 query risk. Consider using includes/preload
# - Association 'comments' has N+1 query risk. Consider using includes/preload
# - Column 'name' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - String column 'email' has no length limit - consider adding one
# - String column 'name' has no length limit - consider adding one
# - String column 'status' has no length limit - consider adding one
# - Column 'status' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class User < ApplicationRecord
  # Associations
  has_many :posts, dependent: :destroy, inverse_of: :user
  has_many :comments, dependent: :destroy, inverse_of: :user

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive suspended] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status ||= 'active'
  end
end

