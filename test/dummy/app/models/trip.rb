# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "trips"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "vehicle_id", type = "integer", null = false },
#   { name = "owner_id", type = "integer", null = false },
#   { name = "start_date", type = "date" },
#   { name = "end_date", type = "date" },
#   { name = "distance", type = "decimal" },
#   { name = "purpose", type = "string" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "trip_type", type = "string" }
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
# notes = ["vehicle:INVERSE_OF", "distance:NOT_NULL", "purpose:NOT_NULL", "trip_type:NOT_NULL", "trip_type:INDEX"]
# <rails-lens:schema:end>
class Trip < VehicleRecord
  belongs_to :vehicle
end

