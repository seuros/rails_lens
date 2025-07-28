# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "families"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", primary_key = true, nullable = false },
#   { name = "name", type = "string", nullable = true },
#   { name = "classification", type = "string", nullable = true },
#   { name = "taxonomic_rank", type = "string", nullable = true },
#   { name = "parent_id", type = "integer", nullable = true },
#   { name = "description", type = "text", nullable = true },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# == Extensions
# == Hierarchy (ClosureTree)
# Parent Column: parent_id
# Hierarchy Table: family_hierarchies
# Order Column: name
#
# == Enums
# - classification: { theropod: "theropod", sauropod: "sauropod", ornithopod: "ornithopod", ceratopsian: "ceratopsian", ankylosaur: "ankylosaur", stegosaur: "stegosaur", pterosaur: "pterosaur", marine: "marine" } (string)
# - taxonomic_rank: { kingdom: "kingdom", phylum: "phylum", class_rank: "class_rank", order_rank: "order", family: "family", genus: "genus", species: "species" } (string)
#
# == Notes
# - Missing index on foreign key 'parent_id'
# - Missing foreign key constraint on 'parent_id' referencing 'families'
# - Association 'ancestor_hierarchies' should specify inverse_of
# - Association 'descendant_hierarchies' should specify inverse_of
# - Association 'species' should specify inverse_of
# - Association 'children' has N+1 query risk. Consider using includes/preload
# - Association 'ancestor_hierarchies' has N+1 query risk. Consider using includes/preload
# - Association 'self_and_ancestors' has N+1 query risk. Consider using includes/preload
# - Association 'descendant_hierarchies' has N+1 query risk. Consider using includes/preload
# - Association 'self_and_descendants' has N+1 query risk. Consider using includes/preload
# - Association 'species' has N+1 query risk. Consider using includes/preload
# - Association 'dinosaurs' has N+1 query risk. Consider using includes/preload
# - Consider adding counter cache for 'parent'
# - Column 'name' should probably have NOT NULL constraint
# - Column 'classification' should probably have NOT NULL constraint
# - Column 'taxonomic_rank' should probably have NOT NULL constraint
# - Column 'description' should probably have NOT NULL constraint
# - String column 'name' has no length limit - consider adding one
# - String column 'classification' has no length limit - consider adding one
# - String column 'taxonomic_rank' has no length limit - consider adding one
# - Large text column 'description' is frequently queried - consider separate storage
# - Missing index on parent column 'parent_id'
# - Hierarchy table 'family_hierarchies' needs compound index on (ancestor_id, descendant_id)
# - Consider adding index on generations column in hierarchy table for depth queries
# - Consider adding counter cache 'children_count' for children count
# <rails-lens:schema:end>
class Family < PrehistoricRecord
  has_closure_tree order: 'name'

  has_many :species
  has_many :dinosaurs, through: :species

  validates :name, presence: true, uniqueness: true
  validates :classification, presence: true
  validates :taxonomic_rank, presence: true

  enum :classification, {
    theropod: 'theropod',
    sauropod: 'sauropod',
    ornithopod: 'ornithopod',
    ceratopsian: 'ceratopsian',
    ankylosaur: 'ankylosaur',
    stegosaur: 'stegosaur',
    pterosaur: 'pterosaur',
    marine: 'marine'

  }

  enum :taxonomic_rank, {
    kingdom: 'kingdom',
    phylum: 'phylum',
    class_rank: 'class_rank',
    order_rank: 'order',
    family: 'family',
    genus: 'genus',
    species: 'species'
  }
end

