# frozen_string_literal: true

# Establish connections for multi-database models
# We need to do this early to ensure connections are available for tests
if Rails.env.test? || Rails.env.development?
  Rails.application.config.to_prepare do
    begin
      VehicleRecord.establish_connection(:vehicles) unless VehicleRecord.connected?
      Rails.logger.info "VehicleRecord connected to vehicles database"
    rescue StandardError => e
      Rails.logger.warn "Failed to connect VehicleRecord to vehicles database: #{e.message}"
    end

    begin
      PrehistoricRecord.establish_connection(:prehistoric) unless PrehistoricRecord.connected?
      Rails.logger.info "PrehistoricRecord connected to prehistoric database"
    rescue StandardError => e
      Rails.logger.warn "Failed to connect PrehistoricRecord to prehistoric database: #{e.message}"
    end
  end
end