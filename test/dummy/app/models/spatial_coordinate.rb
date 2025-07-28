# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "spatial_coordinates"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "location", type = "st_geometry", nullable = true },
#   { name = "coordinates", type = "st_point", nullable = true },
#   { name = "sensor_data", type = "jsonb", nullable = true },
#   { name = "metadata", type = "json", nullable = true },
#   { name = "ip_address", type = "inet", nullable = true },
#   { name = "tracking_id", type = "uuid", nullable = true },
#   { name = "altitude", type = "float", nullable = true },
#   { name = "longitude", type = "decimal", nullable = true },
#   { name = "latitude", type = "decimal", nullable = true },
#   { name = "recorded_at", type = "datetime", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "spaceship_id", type = "integer", nullable = false }
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
# == Notes
# - Association 'spaceship' should specify inverse_of
# - Column 'location' should probably have NOT NULL constraint
# - Column 'coordinates' should probably have NOT NULL constraint
# - Column 'sensor_data' should probably have NOT NULL constraint
# - Column 'metadata' should probably have NOT NULL constraint
# - Column 'ip_address' should probably have NOT NULL constraint
# - Column 'altitude' should probably have NOT NULL constraint
# - Column 'longitude' should probably have NOT NULL constraint
# - Column 'latitude' should probably have NOT NULL constraint
# - UUID column 'tracking_id' should be indexed for better query performance
# <rails-lens:schema:end>
class SpatialCoordinate < ApplicationRecord
  belongs_to :spaceship
end

