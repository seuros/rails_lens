# frozen_string_literal: true

module RailsLens
  module ERD
    class ColumnTypeFormatter
      def self.format(column)
        new(column).format
      end

      def initialize(column)
        @column = column
      end

      def format
        # Default to the generic type
        case @column.type
        when :integer, :bigint then 'int'
        when :string, :text then 'varchar'
        when :boolean then 'boolean'
        when :decimal, :float then 'decimal'
        when :date then 'date'
        when :datetime, :timestamp then 'datetime'
        when :time then 'time'
        when :binary then 'blob'
        when :json, :jsonb then 'json'
        else
          @column.type.to_s
        end
      end
    end
  end
end
