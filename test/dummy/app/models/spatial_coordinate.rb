# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "spatial_coordinates"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "location", type = "st_geometry" },
#   { name = "coordinates", type = "st_point" },
#   { name = "sensor_data", type = "jsonb" },
#   { name = "metadata", type = "json" },
#   { name = "ip_address", type = "inet" },
#   { name = "tracking_id", type = "uuid" },
#   { name = "altitude", type = "float" },
#   { name = "longitude", type = "decimal" },
#   { name = "latitude", type = "decimal" },
#   { name = "recorded_at", type = "datetime" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "spaceship_id", type = "integer", null = false }
# ]
#
# indexes = [
#   { name = "index_spatial_coordinates_on_coordinates", columns = ["coordinates"] },
#   { name = "index_spatial_coordinates_on_location", columns = ["location"] },
#   { name = "index_spatial_coordinates_on_spaceship_id", columns = ["spaceship_id"] }
# ]
#
# foreign_keys = [
#   { column = "spaceship_id", references_table = "spaceships", references_column = "id", name = "fk_rails_69751d644a" }
# ]
#
# notes = ["spaceship:INVERSE_OF", "location:NOT_NULL", "coordinates:NOT_NULL", "sensor_data:NOT_NULL", "metadata:NOT_NULL", "ip_address:NOT_NULL", "altitude:NOT_NULL", "longitude:NOT_NULL", "latitude:NOT_NULL", "tracking_id:INDEX"]
# <rails-lens:schema:end>
class SpatialCoordinate < ApplicationRecord
  belongs_to :spaceship
end

