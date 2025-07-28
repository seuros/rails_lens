# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "order_line_items"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "order_id", type = "integer", nullable = false },
#   { name = "line_number", type = "integer", nullable = false },
#   { name = "quantity", type = "integer", nullable = false, default = "1" },
#   { name = "unit_price", type = "decimal", nullable = false },
#   { name = "total_price", type = "decimal", nullable = true },
#   { name = "product_name", type = "string", nullable = true },
#   { name = "notes", type = "text", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# indexes = [
#   { name = "index_order_line_items_on_order_id", columns = ["order_id"] },
#   { name = "index_order_line_items_on_order_id_and_line_number", columns = ["order_id", "line_number"], unique = true }
# ]
#
# == Composite Primary Key
# Primary Keys: order_id, line_number
#
# == Notes
# - Column 'total_price' should probably have NOT NULL constraint
# - Column 'product_name' should probably have NOT NULL constraint
# - Column 'notes' should probably have NOT NULL constraint
# - String column 'product_name' has no length limit - consider adding one
# <rails-lens:schema:end>
class OrderLineItem < ApplicationRecord
  # Composite primary key using PostgreSQL
  self.primary_key = [:order_id, :line_number]

  # This simulates what the composite_primary_keys gem would do
  def self.primary_keys
    primary_key
  end

  def self.respond_to_missing?(method_name, include_private = false)
    method_name == :primary_keys || super
  end

  # Associations would go here
  # belongs_to :order
  # belongs_to :product

  # Validations
  validates :order_id, presence: true
  validates :line_number, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
end