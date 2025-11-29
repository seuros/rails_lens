# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "owners"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "email", type = "string" },
#   { name = "phone", type = "string" },
#   { name = "address", type = "text" },
#   { name = "date_of_birth", type = "date" },
#   { name = "license_number", type = "string" },
#   { name = "credit_score", type = "integer" },
#   { name = "net_worth", type = "decimal" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "license_class", type = "string" }
# ]
#
# [enums]
# license_class = { class_a = "class_a", class_b = "class_b", class_c = "class_c", motorcycle = "motorcycle", cdl = "cdl" }
#
# notes = ["vehicle_owners:N_PLUS_ONE", "vehicles:N_PLUS_ONE", "name:NOT_NULL", "email:NOT_NULL", "phone:NOT_NULL", "address:NOT_NULL", "date_of_birth:NOT_NULL", "license_number:NOT_NULL", "credit_score:NOT_NULL", "net_worth:NOT_NULL", "license_class:NOT_NULL", "email:INDEX", "address:STORAGE"]
# <rails-lens:schema:end>
class Owner < VehicleRecord
  # Enums
  enum :license_class, {
    class_a: 'class_a',
    class_b: 'class_b',
    class_c: 'class_c',
    motorcycle: 'motorcycle',
    cdl: 'cdl'
  }, suffix: true

  # Associations
  has_many :vehicle_owners, dependent: :destroy, inverse_of: :owner
  has_many :vehicles, through: :vehicle_owners

  # Validations
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :address, presence: true
  validates :date_of_birth, presence: true
  validates :license_number, presence: true, uniqueness: true
  validates :credit_score, presence: true, numericality: { in: 300..850 }
  validates :net_worth, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :license_class, presence: true
  validate :age_requirement

  # Scopes
  scope :by_license_class, ->(license_class) { where(license_class: license_class) }
  scope :high_credit, -> { where('credit_score >= ?', 700) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def age_requirement
    return if date_of_birth.blank?

    age = ((Date.current - date_of_birth) / 365.25).to_i
    return unless age < 18

    errors.add(:date_of_birth, 'must be at least 18 years old')
  end
end
