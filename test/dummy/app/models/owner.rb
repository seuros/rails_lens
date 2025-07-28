# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "owners"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "email", type = "string", nullable = true },
#   { name = "phone", type = "string", nullable = true },
#   { name = "address", type = "text", nullable = true },
#   { name = "date_of_birth", type = "date", nullable = true },
#   { name = "license_number", type = "string", nullable = true },
#   { name = "credit_score", type = "integer", nullable = true },
#   { name = "net_worth", type = "decimal", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "license_class", type = "string", nullable = true }
# ]
#
# == Enums
# - license_class: { class_a: "class_a", class_b: "class_b", class_c: "class_c", motorcycle: "motorcycle", cdl: "cdl" } (string)
#
# == Notes
# - Association 'vehicle_owners' has N+1 query risk. Consider using includes/preload
# - Association 'vehicles' has N+1 query risk. Consider using includes/preload
# - Column 'name' should probably have NOT NULL constraint
# - Column 'email' should probably have NOT NULL constraint
# - Column 'phone' should probably have NOT NULL constraint
# - Column 'address' should probably have NOT NULL constraint
# - Column 'date_of_birth' should probably have NOT NULL constraint
# - Column 'license_number' should probably have NOT NULL constraint
# - Column 'credit_score' should probably have NOT NULL constraint
# - Column 'net_worth' should probably have NOT NULL constraint
# - Column 'license_class' should probably have NOT NULL constraint
# - Column 'email' is commonly used in queries - consider adding an index
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
