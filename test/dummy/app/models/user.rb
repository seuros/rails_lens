# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "users"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "email", type = "string", null = false },
#   { name = "name", type = "string" },
#   { name = "status", type = "string", default = "active" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_users_on_email", columns = ["email"], unique = true }
# ]
#
# [callbacks]
# before_validation = [{ method = "set_default_status" }, { method = "normalize_email", if = ["email_changed?"] }]
# after_save = [{ method = "sync_to_crm", if = ["proc"] }]
# after_commit = [{ method = "send_welcome_email" }]
#
# notes = ["posts:N_PLUS_ONE", "comments:N_PLUS_ONE", "name:NOT_NULL", "status:NOT_NULL", "email:LIMIT", "name:LIMIT", "status:LIMIT", "status:INDEX"]
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
  before_validation :normalize_email, if: :email_changed?
  after_save :sync_to_crm, if: -> { saved_change_to_status? }
  after_commit :send_welcome_email, on: :create

  private

  def set_default_status
    self.status ||= 'active'
  end

  def normalize_email
    # Downcase and strip whitespace from email
    # self.email = email.downcase.strip
  end

  def sync_to_crm
    # Sync user status change to external CRM
    # CrmService.update_contact(self, status: status)
  end

  def send_welcome_email
    # Send welcome email after user is committed to database
    # UserMailer.welcome(self).deliver_later
  end
end

