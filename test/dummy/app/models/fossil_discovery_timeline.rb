# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "fossil_discovery_timeline"
# database_dialect = "SQLite"
# view_type = "regular"
# updatable = true
#
# columns = [
#   { name = "dinosaur_id", type = "integer", nullable = true },
#   { name = "dinosaur_name", type = "string", nullable = true },
#   { name = "species", type = "string", nullable = true },
#   { name = "period", type = "string", nullable = true },
#   { name = "diet", type = "string", nullable = true },
#   { name = "length", type = "decimal", nullable = true },
#   { name = "weight", type = "decimal", nullable = true },
#   { name = "site_id", type = "integer", nullable = true },
#   { name = "site_name", type = "string", nullable = true },
#   { name = "location", type = "string", nullable = true },
#   { name = "depth", type = "decimal", nullable = true },
#   { name = "rock_formation", type = "string", nullable = true },
#   { name = "fossil_discovered_date", type = "date", nullable = true },
#   { name = "completeness", type = "decimal", nullable = true },
#   { name = "fossil_condition", type = "string", nullable = true },
#   { name = "days_between_discoveries", type = "", nullable = true },
#   { name = "species_fossil_count", type = "", nullable = true },
#   { name = "discovery_sequence_at_site", type = "", nullable = true },
#   { name = "completeness_grade", type = "", nullable = true },
#   { name = "geological_era", type = "", nullable = true }
# ]
#
# view_dependencies = ["dinosaurs", "excavation_sites", "fossil_discoveries"]
#
# == View Information
# View Type: regular
# Updatable: Yes
# Dependencies: dinosaurs, excavation_sites, fossil_discoveries
# Definition: CREATE VIEW fossil_discovery_timeline AS SELECT d.id as dinosaur_id, d.name as dinosaur_name, d.species, d.period, d.diet, d.length, d.weight, es.id as site_id, es.name as site_name,...
#
# == Notes
# - 👁️ View-backed model: read-only
# <rails-lens:schema:end>
# SQLite View: Fossil discovery timeline with geological analysis
class FossilDiscoveryTimeline < PrehistoricRecord
  self.table_name = 'fossil_discovery_timeline'
  self.primary_key = 'dinosaur_id'
  
  readonly
  
  # Associations
  belongs_to :dinosaur, foreign_key: 'dinosaur_id'
  belongs_to :excavation_site, foreign_key: 'site_id'
  
  # Scopes for geological periods
  scope :mesozoic_era, -> { where(geological_era: ['Early Mesozoic', 'Middle Mesozoic', 'Late Mesozoic']) }
  scope :jurassic_period, -> { where(period: 'Jurassic') }
  scope :cretaceous_period, -> { where(period: 'Cretaceous') }
  
  # Scopes for fossil quality
  scope :exceptional_finds, -> { where(completeness_grade: 'Exceptional') }
  scope :well_preserved, -> { where(completeness_grade: ['Exceptional', 'Excellent']) }
  scope :recent_discoveries, -> { where('fossil_discovered_date > ?', 5.years.ago) }
  
  # Scopes for site analysis
  scope :first_discoveries_at_site, -> { where(discovery_sequence_at_site: 1) }
  scope :prolific_sites, -> { where('species_fossil_count > ?', 5) }
  
  # Instance methods for interpretation
  def discovery_timeline_category
    case days_between_discoveries
    when nil then 'Unknown'
    when -Float::INFINITY..0 then 'Before Species Discovery'
    when 1..30 then 'Shortly After'
    when 31..365 then 'Same Year'
    when 366..1825 then 'Within 5 Years'
    else 'Long After'
    end
  end
  
  def geological_significance
    score = 0
    score += 30 if completeness_grade == 'Exceptional'
    score += 20 if discovery_sequence_at_site == 1
    score += 15 if species_fossil_count < 3
    score += 10 if period == 'Triassic' # Rarer period
    
    case score
    when 50..Float::INFINITY then 'Highly Significant'
    when 30..49 then 'Very Significant' 
    when 15..29 then 'Moderately Significant'
    else 'Standard Significance'
    end
  end
  
  def preservation_quality_score
    case completeness_grade
    when 'Exceptional' then 100
    when 'Excellent' then 80
    when 'Good' then 60
    when 'Fair' then 40
    when 'Poor' then 20
    else 0
    end
  end
end