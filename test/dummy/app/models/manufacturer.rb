# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "manufacturers"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "country", type = "string" },
#   { name = "founded_year", type = "integer" },
#   { name = "headquarters", type = "text" },
#   { name = "website", type = "string" },
#   { name = "annual_revenue", type = "decimal" },
#   { name = "active", type = "boolean" },
#   { name = "logo_url", type = "string" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "status", type = "string" },
#   { name = "company_type", type = "string" }
# ]
#
# [extensions]
# [closure_tree]
# parent_column = "parent_id"
# hierarchy_table = "manufacturer_hierarchies"
# order_column = "name"
#
# [enums]
# status = { active = "active", defunct = "defunct", acquired = "acquired" }
# company_type = { conglomerate = "conglomerate", parent_company = "parent_company", subsidiary = "subsidiary", division = "division", brand = "brand", factory = "factory" }
#
# notes = ["parent_id:INDEX", "parent_id:FK_CONSTRAINT", "ancestor_hierarchies:INVERSE_OF", "descendant_hierarchies:INVERSE_OF", "vehicles:INVERSE_OF", "children:N_PLUS_ONE", "ancestor_hierarchies:N_PLUS_ONE", "self_and_ancestors:N_PLUS_ONE", "descendant_hierarchies:N_PLUS_ONE", "self_and_descendants:N_PLUS_ONE", "vehicles:N_PLUS_ONE", "parent:COUNTER_CACHE", "name:NOT_NULL", "country:NOT_NULL", "founded_year:NOT_NULL", "headquarters:NOT_NULL", "website:NOT_NULL", "annual_revenue:NOT_NULL", "active:NOT_NULL", "logo_url:NOT_NULL", "status:NOT_NULL", "company_type:NOT_NULL", "active:DEFAULT", "status:DEFAULT", "status:INDEX", "company_type:INDEX", "headquarters:STORAGE", "manufacturer_hierarchies:COMP_INDEX", "generations:INDEX", "children:COUNTER_CACHE"]
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

