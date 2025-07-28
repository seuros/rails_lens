# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "trips"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "vehicle_id", type = "integer", nullable = false },
#   { name = "owner_id", type = "integer", nullable = false },
#   { name = "start_date", type = "date", nullable = true },
#   { name = "end_date", type = "date", nullable = true },
#   { name = "distance", type = "decimal", nullable = true },
#   { name = "purpose", type = "string", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "trip_type", type = "string", nullable = true }
# ]
#
# indexes = [
#   { name = "index_trips_on_owner_id", columns = ["owner_id"] },
#   { name = "index_trips_on_vehicle_id", columns = ["vehicle_id"] }
# ]
#
# foreign_keys = [
#   { column = "vehicle_id", references_table = "vehicles", references_column = "id", name = "fk_rails_272ac73176" },
#   { column = "owner_id", references_table = "owners", references_column = "id", name = "fk_rails_9b563cd750" }
# ]
#
# == Notes
# - Association 'vehicle' should specify inverse_of
# - Column 'distance' should probably have NOT NULL constraint
# - Column 'purpose' should probably have NOT NULL constraint
# - Column 'trip_type' should probably have NOT NULL constraint
# - Column 'trip_type' is commonly used in queries - consider adding an index
# <rails-lens:schema:end>
class Trip < VehicleRecord
  belongs_to :vehicle
end

