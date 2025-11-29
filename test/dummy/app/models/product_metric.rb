# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "product_metrics"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "product_id", type = "integer", null = false },
#   { name = "views", type = "integer", null = false, default = "0" },
#   { name = "purchases", type = "integer", null = false, default = "0" },
#   { name = "revenue", type = "decimal", default = "0.0" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "conversion_rate", type = "decimal" },
#   { name = "average_order_value", type = "decimal" }
# ]
#
# indexes = [
#   { name = "index_product_metrics_on_conversion_rate", columns = ["conversion_rate"] },
#   { name = "index_product_metrics_on_product_id", columns = ["product_id"] }
# ]
#
# foreign_keys = [
#   { column = "product_id", references_table = "products", references_column = "id", name = "fk_rails_51259df091" }
# ]
#
# check_constraints = [
#   { name = "check_positive_purchases", expression = "purchases >= 0" },
#   { name = "check_positive_revenue", expression = "revenue >= 0::numeric" },
#   { name = "check_positive_views", expression = "views >= 0" }
# ]
#
# [check_constraints]
# constraints = [{ name = "check_positive_purchases", expr = "purchases >= 0" }, { name = "check_positive_revenue", expr = "revenue >= 0::numeric" }, { name = "check_positive_views", expr = "views >= 0" }]
#
# [generated_columns]
# columns = [{ name = "conversion_rate", expr = "
# CASE
#     WHEN (views > 0) THEN (((purchases)::numeric / (views)::numeric) * (100)::numeric)
#     ELSE (0)::numeric
# END" }, { name = "average_order_value", expr = "
# CASE
#     WHEN (purchases > 0) THEN (revenue / (purchases)::numeric)
#     ELSE (0)::numeric
# END" }]
#
# notes = ["product:INVERSE_OF", "revenue:NOT_NULL", "conversion_rate:NOT_NULL", "average_order_value:NOT_NULL"]
# <rails-lens:schema:end>
class ProductMetric < ApplicationRecord
  # Associations
  belongs_to :product

  # Validations
  validates :views, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :purchases, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :revenue, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :high_conversion, -> { where('conversion_rate > ?', 10) }
  scope :high_revenue, -> { where('revenue > ?', 1000) }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def increment_views!
    increment!(:views)
  end

  def record_purchase!(amount)
    self.purchases += 1
    self.revenue += amount
    save!
  end
end

