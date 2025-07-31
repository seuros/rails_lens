# frozen_string_literal: true

module RailsLens
  # Extracts and manages metadata for database views and materialized views
  class ViewMetadata
    attr_reader :model_class, :connection, :table_name

    def initialize(model_class)
      @model_class = model_class
      @connection = model_class.connection
      @table_name = model_class.table_name
      @adapter_name = connection.adapter_name.downcase
      @adapter = create_adapter
    end

    def view_type
      return nil unless view_exists?

      @adapter&.view_type
    end

    def view_exists?
      ModelDetector.view_exists?(model_class)
    end

    def materialized_view?
      view_type == 'materialized'
    end

    def regular_view?
      view_type == 'regular'
    end

    def updatable?
      return false unless view_exists?

      @adapter&.view_updatable? || false
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined
      false
    end

    def dependencies
      return [] unless view_exists?

      @adapter&.view_dependencies || []
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined
      []
    end

    def refresh_strategy
      return nil unless materialized_view?

      @adapter&.view_refresh_strategy
    end

    def last_refreshed
      return nil unless materialized_view?

      @adapter&.view_last_refreshed
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined
      nil
    end

    def view_definition
      return nil unless view_exists?

      @adapter&.view_definition
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined
      nil
    end

    def to_h
      {
        view_type: view_type,
        updatable: updatable?,
        dependencies: dependencies,
        refresh_strategy: refresh_strategy,
        last_refreshed: last_refreshed,
        view_definition: view_definition
      }.compact
    end

    private

    def create_adapter
      case @adapter_name
      when 'postgresql'
        Schema::Adapters::Postgresql.new(connection, table_name)
      when 'mysql', 'mysql2'
        Schema::Adapters::Mysql.new(connection, table_name)
      when 'sqlite', 'sqlite3'
        Schema::Adapters::Sqlite3.new(connection, table_name)
      else
        nil
      end
    end
  end
end
