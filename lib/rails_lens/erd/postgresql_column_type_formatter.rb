# frozen_string_literal: true

module RailsLens
  module ERD
    class PostgresqlColumnTypeFormatter < ColumnTypeFormatter
      def format
        case @column.sql_type
        when /jsonb/i then 'jsonb'
        when /uuid/i then 'uuid'
        when /inet/i then 'inet'
        when /array/i then 'array'
        when /tsvector/i then 'tsvector'
        else
          super
        end
      end
    end
  end
end
