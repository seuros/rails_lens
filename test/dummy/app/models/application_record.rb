# frozen_string_literal: true

# <rails-lens:schema:begin>
# database_dialect = "PostgreSQL"
# [database_functions]
# functions = [
#   { name = "update_posts_comments_count", schema = "public", language = "plpgsql", return_type = "trigger", description = "Maintains the comments_count cache counter on the posts table" }
# ]
# <rails-lens:schema:end>
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
