# frozen_string_literal: true

# <rails-lens:schema:begin>
# database_dialect = "Mysql2"
# <rails-lens:schema:end>
class VehicleRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :vehicles
end
