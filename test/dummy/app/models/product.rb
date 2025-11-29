# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "products"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string", null = false },
#   { name = "description", type = "text" },
#   { name = "price", type = "decimal", null = false },
#   { name = "category", type = "string" },
#   { name = "active", type = "boolean", null = false, default = "true" },
#   { name = "sku", type = "string" },
#   { name = "stock_quantity", type = "integer", default = "0" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_products_on_active", columns = ["active"] },
#   { name = "index_products_on_category", columns = ["category"] },
#   { name = "index_products_on_name", columns = ["name"] },
#   { name = "index_products_on_sku", columns = ["sku"], unique = true }
# ]
#
# notes = ["product_metrics:INVERSE_OF", "product_metrics:N_PLUS_ONE", "description:NOT_NULL", "category:NOT_NULL", "sku:NOT_NULL", "stock_quantity:NOT_NULL", "name:LIMIT", "category:LIMIT", "sku:LIMIT", "description:STORAGE"]
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