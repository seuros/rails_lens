# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "families"
# database_dialect = "SQLite"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "name", type = "string" },
#   { name = "classification", type = "string" },
#   { name = "taxonomic_rank", type = "string" },
#   { name = "parent_id", type = "integer" },
#   { name = "description", type = "text" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# [extensions]
# [closure_tree]
# parent_column = "parent_id"
# hierarchy_table = "family_hierarchies"
# order_column = "name"
#
# [enums]
# classification = { theropod = "theropod", sauropod = "sauropod", ornithopod = "ornithopod", ceratopsian = "ceratopsian", ankylosaur = "ankylosaur", stegosaur = "stegosaur", pterosaur = "pterosaur", marine = "marine" }
# taxonomic_rank = { kingdom = "kingdom", phylum = "phylum", class_rank = "class_rank", order_rank = "order", family = "family", genus = "genus", species = "species" }
#
# notes = ["parent_id:INDEX", "parent_id:FK_CONSTRAINT", "ancestor_hierarchies:INVERSE_OF", "descendant_hierarchies:INVERSE_OF", "species:INVERSE_OF", "children:N_PLUS_ONE", "ancestor_hierarchies:N_PLUS_ONE", "self_and_ancestors:N_PLUS_ONE", "descendant_hierarchies:N_PLUS_ONE", "self_and_descendants:N_PLUS_ONE", "species:N_PLUS_ONE", "dinosaurs:N_PLUS_ONE", "parent:COUNTER_CACHE", "name:NOT_NULL", "classification:NOT_NULL", "taxonomic_rank:NOT_NULL", "description:NOT_NULL", "name:LIMIT", "classification:LIMIT", "taxonomic_rank:LIMIT", "description:STORAGE", "family_hierarchies:COMP_INDEX", "generations:INDEX", "children:COUNTER_CACHE"]
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

