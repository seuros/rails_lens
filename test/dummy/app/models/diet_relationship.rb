# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "diet_relationships"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "predator_id", type = "integer", null = false },
#   { name = "prey_id", type = "integer", null = false },
#   { name = "relationship_type", type = "string" },
#   { name = "intensity", type = "integer" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false },
#   { name = "evidence_type", type = "string" }
# ]
#
# indexes = [
#   { name = "index_diet_relationships_on_prey_id", columns = ["prey_id"] },
#   { name = "index_diet_relationships_on_predator_id", columns = ["predator_id"] }
# ]
#
# foreign_keys = [
#   { column = "prey_id", references_table = "species", references_column = "id" },
#   { column = "predator_id", references_table = "species", references_column = "id" }
# ]
#
# [enums]
# evidence_type = { stomach_contents = "stomach_contents", coprolite = "coprolite", bite_marks = "bite_marks", tooth_marks = "tooth_marks", behavioral = "behavioral", anatomical = "anatomical" }
#
# notes = ["predator_id+prey_id:COMP_INDEX", "relationship_type:NOT_NULL", "intensity:NOT_NULL", "evidence_type:NOT_NULL", "relationship_type:LIMIT", "relationship_type:INDEX", "evidence_type:INDEX"]
# <rails-lens:schema:end>
class DietRelationship < PrehistoricRecord
  # Enums
  enum :evidence_type, {
    stomach_contents: 'stomach_contents',
    coprolite: 'coprolite',
    bite_marks: 'bite_marks',
    tooth_marks: 'tooth_marks',
    behavioral: 'behavioral',
    anatomical: 'anatomical'
  }, suffix: true

  # Associations
  belongs_to :predator, class_name: 'Species', inverse_of: :predator_relationships
  belongs_to :prey, class_name: 'Species', foreign_key: :prey_id, inverse_of: :prey_relationships

  # Validations
  validates :relationship_type, presence: true
  validates :intensity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :evidence_type, presence: true
  validate :different_species

  private

  def different_species
    errors.add(:prey_id, "can't be the same as predator") if predator_id == prey_id
  end
end

