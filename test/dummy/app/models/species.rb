# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "species"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "family_id", type = "integer", nullable = false },
#   { name = "average_lifespan", type = "integer", nullable = true },
#   { name = "habitat", type = "text", nullable = true },
#   { name = "danger_level", type = "integer", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "locomotion", type = "string", nullable = true }
# ]
#
# == Notes
# - Association 'family' should specify inverse_of
# - Association 'dinosaurs' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'family'
# - Column 'name' should probably have NOT NULL constraint
# - Column 'average_lifespan' should probably have NOT NULL constraint
# - Column 'habitat' should probably have NOT NULL constraint
# - Column 'danger_level' should probably have NOT NULL constraint
# - Column 'locomotion' should probably have NOT NULL constraint
# - String column 'name' has no length limit - consider adding one
# <rails-lens:schema:end>
class Species < PrehistoricRecord
  belongs_to :family
  has_many :dinosaurs
end

