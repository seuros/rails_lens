# frozen_string_literal: true

class VehicleRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :vehicles
end
