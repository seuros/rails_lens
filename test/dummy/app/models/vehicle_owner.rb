# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "vehicle_owners"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "vehicle_id", type = "integer", null = false },
#   { name = "owner_id", type = "integer", null = false },
#   { name = "ownership_start", type = "date" },
#   { name = "ownership_end", type = "date" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_vehicle_owners_on_owner_id", columns = ["owner_id"] },
#   { name = "index_vehicle_owners_on_vehicle_id", columns = ["vehicle_id"] }
# ]
#
# foreign_keys = [
#   { column = "vehicle_id", references_table = "vehicles", references_column = "id", name = "fk_rails_25f750ed19" },
#   { column = "owner_id", references_table = "owners", references_column = "id", name = "fk_rails_f12ecc0d84" }
# ]
#
# notes = ["vehicle:INVERSE_OF", "owner:INVERSE_OF", "ownership_start:NOT_NULL", "ownership_end:NOT_NULL"]
# <rails-lens:schema:end>
class VehicleOwner < VehicleRecord
  belongs_to :vehicle
  belongs_to :owner
end

