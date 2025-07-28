# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "products"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = false },
#   { name = "description", type = "text", nullable = true },
#   { name = "price", type = "decimal", nullable = false },
#   { name = "category", type = "string", nullable = true },
#   { name = "active", type = "boolean", nullable = false, default = "true" },
#   { name = "sku", type = "string", nullable = true },
#   { name = "stock_quantity", type = "integer", nullable = true, default = "0" },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# indexes = [
#   { name = "index_products_on_active", columns = ["active"] },
#   { name = "index_products_on_category", columns = ["category"] },
#   { name = "index_products_on_name", columns = ["name"] },
#   { name = "index_products_on_sku", columns = ["sku"], unique = true }
# ]
#
# == Notes
# - Association 'product_metrics' should specify inverse_of
# - Association 'product_metrics' has N+1 query risk. Consider using includes/preload
# - Column 'description' should probably have NOT NULL constraint
# - Column 'category' should probably have NOT NULL constraint
# - Column 'sku' should probably have NOT NULL constraint
# - Column 'stock_quantity' should probably have NOT NULL constraint
# - String column 'name' has no length limit - consider adding one
# - String column 'category' has no length limit - consider adding one
# - String column 'sku' has no length limit - consider adding one
# - Large text column 'description' is frequently queried - consider separate storage
# <rails-lens:schema:end>
class Product < ApplicationRecord
  # Associations
  has_many :product_metrics, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
end