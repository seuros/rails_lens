# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "diet_relationships"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "predator_id", type = "integer", nullable = false },
#   { name = "prey_id", type = "integer", nullable = false },
#   { name = "relationship_type", type = "string", nullable = true },
#   { name = "intensity", type = "integer", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false },
#   { name = "evidence_type", type = "string", nullable = true }
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
# == Enums
# - evidence_type: { stomach_contents: "stomach_contents", coprolite: "coprolite", bite_marks: "bite_marks", tooth_marks: "tooth_marks", behavioral: "behavioral", anatomical: "anatomical" } (string)
#
# == Notes
# - Consider composite index on [predator_id, prey_id] for common query pattern
# - Column 'relationship_type' should probably have NOT NULL constraint
# - Column 'intensity' should probably have NOT NULL constraint
# - Column 'evidence_type' should probably have NOT NULL constraint
# - String column 'relationship_type' has no length limit - consider adding one
# - Column 'relationship_type' is commonly used in queries - consider adding an index
# - Column 'evidence_type' is commonly used in queries - consider adding an index
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

