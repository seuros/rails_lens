# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "species"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "family_id", type = "integer", null = false },
#   { name = "average_lifespan", type = "integer" },
#   { name = "habitat", type = "text" },
#   { name = "danger_level", type = "integer" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "locomotion", type = "string" }
# ]
#
# indexes = [
#   { name = "index_species_on_family_id", columns = ["family_id"] }
# ]
#
# foreign_keys = [
#   { column = "family_id", references_table = "families", references_column = "id" }
# ]
#
# notes = ["family:INVERSE_OF", "dinosaurs:N_PLUS_ONE", "family:COUNTER_CACHE", "name:NOT_NULL", "average_lifespan:NOT_NULL", "habitat:NOT_NULL", "danger_level:NOT_NULL", "locomotion:NOT_NULL", "name:LIMIT", "habitat:STORAGE"]
# <rails-lens:schema:end>
class Species < PrehistoricRecord
  belongs_to :family
  has_many :dinosaurs
end

