# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "triggers"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "description", type = "text" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# notes = ["name:NOT_NULL", "description:NOT_NULL", "name:LIMIT", "description:STORAGE"]
# <rails-lens:schema:end>
# Test model with a table name that collides with a PostgreSQL system view
# (information_schema.triggers). This is used to verify that the ModelDetector
# correctly filters system schemas when checking for views.
class Trigger < ApplicationRecord
end
