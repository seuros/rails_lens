# frozen_string_literal: true

module RailsLens
  module ERD
    class MysqlColumnTypeFormatter < ColumnTypeFormatter
      def format
        case @column.sql_type
        when /json/i then 'json'
        when /enum/i then 'enum'
        when /set/i then 'set'
        when /mediumtext/i then 'mediumtext'
        when /tinyint\(1\)/i then 'boolean'
        else
          super
        end
      end
    end
  end
end
