# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "manufacturers"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "country", type = "string", nullable = true },
#   { name = "founded_year", type = "integer", nullable = true },
#   { name = "headquarters", type = "text", nullable = true },
#   { name = "website", type = "string", nullable = true },
#   { name = "annual_revenue", type = "decimal", nullable = true },
#   { name = "active", type = "boolean", nullable = true },
#   { name = "logo_url", type = "string", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "status", type = "string", nullable = true },
#   { name = "company_type", type = "string", nullable = true }
# ]
#
# == Extensions
# == Hierarchy (ClosureTree)
# Parent Column: parent_id
# Hierarchy Table: manufacturer_hierarchies
# Order Column: name
#
# == Enums
# - status: { active: "active", defunct: "defunct", acquired: "acquired" } (string)
# - company_type: { conglomerate: "conglomerate", parent_company: "parent_company", subsidiary: "subsidiary", division: "division", brand: "brand", factory: "factory" } (string)
#
# == Notes
# - Missing index on foreign key 'parent_id'
# - Missing foreign key constraint on 'parent_id' referencing 'manufacturers'
# - Association 'ancestor_hierarchies' should specify inverse_of
# - Association 'descendant_hierarchies' should specify inverse_of
# - Association 'vehicles' should specify inverse_of
# - Association 'children' has N+1 query risk. Consider using includes/preload
# - Association 'ancestor_hierarchies' has N+1 query risk. Consider using includes/preload
# - Association 'self_and_ancestors' has N+1 query risk. Consider using includes/preload
# - Association 'descendant_hierarchies' has N+1 query risk. Consider using includes/preload
# - Association 'self_and_descendants' has N+1 query risk. Consider using includes/preload
# - Association 'vehicles' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'parent'
# - Column 'name' should probably have NOT NULL constraint
# - Column 'country' should probably have NOT NULL constraint
# - Column 'founded_year' should probably have NOT NULL constraint
# - Column 'headquarters' should probably have NOT NULL constraint
# - Column 'website' should probably have NOT NULL constraint
# - Column 'annual_revenue' should probably have NOT NULL constraint
# - Column 'active' should probably have NOT NULL constraint
# - Column 'logo_url' should probably have NOT NULL constraint
# - Column 'status' should probably have NOT NULL constraint
# - Column 'company_type' should probably have NOT NULL constraint
# - Boolean column 'active' should have a default value
# - Status column 'status' should have a default value
# - Column 'status' is commonly used in queries - consider adding an index
# - Column 'company_type' is commonly used in queries - consider adding an index
# - Missing index on parent column 'parent_id'
# - Hierarchy table 'manufacturer_hierarchies' needs compound index on (ancestor_id, descendant_id)
# - Consider adding index on generations column in hierarchy table for depth queries
# - Consider adding counter cache 'children_count' for children count
# <rails-lens:schema:end>
class Manufacturer < VehicleRecord
  # Include ClosureTree for hierarchy
  has_closure_tree order: 'name'

  # Enums
  enum :status, {
    active: 'active',
    defunct: 'defunct',
    acquired: 'acquired'
  }, suffix: true

  enum :company_type, {
    conglomerate: 'conglomerate',
    parent_company: 'parent_company',
    subsidiary: 'subsidiary',
    division: 'division',
    brand: 'brand',
    factory: 'factory'
  }, suffix: true

  # Associations
  has_many :vehicles, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :country, presence: true
  validates :founded_year, presence: true, numericality: { only_integer: true }
  validates :website, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :annual_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, presence: true
  validates :company_type, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(company_type) { where(company_type: company_type) }
  scope :founded_after, ->(year) { where('founded_year > ?', year) }

  # Callbacks
  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.active = true if active.nil?
  end
end

