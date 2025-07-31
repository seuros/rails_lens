# frozen_string_literal: true

# <rails-lens:schema:begin>
# connection = "prehistoric"
# database_dialect = "SQLite"
# database_version = "3.50.3"
#
# # This is an abstract class that establishes a database connection
# # but does not have an associated table.
# <rails-lens:schema:end>
class PrehistoricRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :prehistoric
end
