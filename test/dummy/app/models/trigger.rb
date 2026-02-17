# frozen_string_literal: true

# Test model with a table name that collides with a PostgreSQL system view
# (information_schema.triggers). This is used to verify that the ModelDetector
# correctly filters system schemas when checking for views.
class Trigger < ApplicationRecord
end
