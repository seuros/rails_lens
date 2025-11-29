# frozen_string_literal: true

# <rails-lens:schema:begin>
# database_dialect = "SQLite"
# <rails-lens:schema:end>
class PrehistoricRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :prehistoric
end
