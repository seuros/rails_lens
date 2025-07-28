# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "vehicle_owners"
# database_dialect = "MySQL"
# storage_engine = "InnoDB"
# character_set = "utf8mb4"
# collation = "utf8mb4_unicode_ci"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "vehicle_id", type = "integer", nullable = false },
#   { name = "owner_id", type = "integer", nullable = false },
#   { name = "ownership_start", type = "date", nullable = true },
#   { name = "ownership_end", type = "date", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
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
# == Notes
# - Association 'vehicle' should specify inverse_of
# - Association 'owner' should specify inverse_of
# - Column 'ownership_start' should probably have NOT NULL constraint
# - Column 'ownership_end' should probably have NOT NULL constraint
# <rails-lens:schema:end>
class VehicleOwner < VehicleRecord
  belongs_to :vehicle
  belongs_to :owner
end

