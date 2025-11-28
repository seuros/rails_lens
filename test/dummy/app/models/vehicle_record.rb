# frozen_string_literal: true

# <rails-lens:schema:begin>
# connection = "vehicles"
# database_dialect = "Mysql2"
# database_version = "8.4.7"
# database_name = "rails_lens_vehicles_test"
#
# # This is an abstract class that establishes a database connection
# # but does not have an associated table.
# <rails-lens:schema:end>
class VehicleRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :vehicles
end
