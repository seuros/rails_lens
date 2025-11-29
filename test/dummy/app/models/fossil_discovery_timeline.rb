# frozen_string_literal: true

# <rails-lens:schema:begin>
# view = "fossil_discovery_timeline"
# database_dialect = "SQLite"
# view_type = "regular"
# updatable = false
#
# columns = [
#   { name = "id", type = "integer" },
#   { name = "discovered_at", type = "date" },
#   { name = "completeness", type = "decimal" },
#   { name = "condition", type = "string" },
#   { name = "dinosaur_name", type = "string" },
#   { name = "species", type = "string" },
#   { name = "period", type = "string" },
#   { name = "diet", type = "string" },
#   { name = "excavation_site", type = "string" },
#   { name = "site_location", type = "string" },
#   { name = "excavation_depth", type = "decimal" },
#   { name = "soil_type", type = "string" },
#   { name = "rock_formation", type = "string" },
#   { name = "climate_ancient", type = "string" },
#   { name = "completeness_category", type = "" },
#   { name = "discovery_year", type = "" },
#   { name = "discovery_month", type = "" },
#   { name = "period_order", type = "" }
# ]
#
# view_dependencies = ["dinosaurs", "excavation_sites", "fossil_discoveries"]
#
# [view]
# type = "regular"
# updatable = false
# dependencies = ["dinosaurs", "excavation_sites", "fossil_discoveries"]
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