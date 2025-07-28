# frozen_string_literal: true

class PrehistoricRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :prehistoric
end
