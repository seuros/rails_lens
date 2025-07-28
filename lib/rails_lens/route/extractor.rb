# frozen_string_literal: true

module RailsLens
  module Route
    # Handles extracting route information from Rails application
    class Extractor
      class << self
        # Extract all routes from Rails application
        #
        # @return [Hash] Routes hash organized by controller and action
        def call
          routes = {}

          populate_routes(Rails.application, routes)
          backfill_routes(routes)
        end

        private

        # Recursively populate routes from Rails application (handles engines)
        #
        # @param app [Rails::Application] Rails application instance
        # @param routes [Hash] Collection of all route info
        # @return [void]
        def populate_routes(app, routes)
          app.routes.routes.each do |route|
            if route.app.respond_to?(:engine?) && route.app.engine?
              populate_routes(route.app.app, routes)
              next
            end

            controller, action, defaults, source_path = extract_data_from(route)
            next unless controller && action && source_path

            routes[controller] ||= {}
            routes[controller][action] ||= []

            add_route_info(
              route: route,
              routes: routes,
              controller: controller,
              action: action,
              defaults: defaults,
              source_path: source_path
            )
          end
        end

        # Add formatted route info for the given parameters
        #
        # @param route [ActionDispatch::Journey::Route] Route instance
        # @param routes [Hash] Collection of all route info
        # @param controller [String] Controller name
        # @param action [String] Action name
        # @param defaults [Hash] Default parameters for route
        # @param source_path [String] Path to controller file
        # @return [void]
        def add_route_info(route:, routes:, controller:, action:, defaults:, source_path:)
          verbs_for(route).each do |verb|
            route_info = {
              verb: verb,
              path: route.path.spec.to_s.gsub('(.:format)', ''),
              name: route.name,
              defaults: defaults,
              source_path: source_path
            }

            routes[controller][action].push(route_info)
            routes[controller][action].uniq!
          end
        end

        # Extract HTTP verbs from route
        #
        # @param route [ActionDispatch::Journey::Route] Route instance
        # @return [Array<String>] List of HTTP verbs
        def verbs_for(route)
          route_verb = route.verb.to_s
          %w[GET POST PUT PATCH DELETE].select { |verb| route_verb.include?(verb) }
        end

        # Extract controller, action, defaults, and source path from route
        #
        # @param route [ActionDispatch::Journey::Route] Route instance
        # @return [Array<String, String, Hash, String>] controller, action, defaults, source_path
        def extract_data_from(route)
          defaults = route.defaults.dup
          controller = defaults.delete(:controller)
          action = defaults.delete(:action)

          return [nil, nil, nil, nil] unless controller && action

          begin
            controller_class = "#{controller.underscore.camelize}Controller".constantize
            action_method = action.to_sym

            source_path = if controller_class.method_defined?(action_method)
                            controller_class.instance_method(action_method).source_location&.first
                          end

            [controller, action, defaults, source_path]
          rescue NameError
            [nil, nil, nil, nil]
          end
        end

        # Backfill route names that might be missing
        #
        # @param routes [Hash] Routes hash
        # @return [Hash] Backfilled routes hash
        def backfill_routes(routes)
          paths = {}

          # Map paths to their verbs and names
          routes.each_value do |actions|
            actions.each_value do |data|
              data.each do |datum|
                paths[datum[:path]] ||= {}
                paths[datum[:path]][datum[:verb]] ||= datum[:name]

                # Backfill names for routes that don't have them
                datum[:name] ||= paths.dig(datum[:path], datum[:verb])
                datum[:name] ||= paths[datum[:path]]&.values&.compact&.first
              end
            end
          end

          routes
        end
      end
    end
  end
end
