# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "order_line_items"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "order_id", type = "integer", null = false },
#   { name = "line_number", type = "integer", null = false },
#   { name = "quantity", type = "integer", null = false, default = "1" },
#   { name = "unit_price", type = "decimal", null = false },
#   { name = "total_price", type = "decimal" },
#   { name = "product_name", type = "string" },
#   { name = "notes", type = "text" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_order_line_items_on_order_id", columns = ["order_id"] },
#   { name = "index_order_line_items_on_order_id_and_line_number", columns = ["order_id", "line_number"], unique = true }
# ]
#
# [composite_pk]
# keys = ["order_id", "line_number"]
#
# notes = ["total_price:NOT_NULL", "product_name:NOT_NULL", "notes:NOT_NULL", "product_name:LIMIT", "notes:STORAGE"]
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