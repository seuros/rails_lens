# frozen_string_literal: true

# <rails-lens:schema:begin>
# connection = "primary"
# database_dialect = "PostgreSQL"
# database_version = "180000"
# database_name = "rails_lens_test"
#
# # This is an abstract class that establishes a database connection
# # but does not have an associated table.
# <rails-lens:schema:end>
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
