# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class BestPracticesAnalyzerTest < ActiveSupport::TestCase
      # Mock model class for testing
      class MockModel
        attr_reader :table_name, :columns, :connection

        def initialize(table_name, columns = [], connection = nil)
          @table_name = table_name
          @columns = columns
          @connection = connection || MockConnection.new
        end

        def base_class
          self
        end

        def column_names
          @columns.map(&:name)
        end
      end

      # Mock connection for testing
      class MockConnection
        def initialize(indexes = [])
          @indexes = indexes
        end

        def indexes(_table_name)
          @indexes
        end
      end

      # Mock column for testing
      MockColumn = Struct.new(:name, :type, :null, :default, keyword_init: true)

      # Mock index for testing
      MockIndex = Struct.new(:columns, :unique, keyword_init: true)

      def setup
        @timestamp_columns = [
          MockColumn.new(name: 'id', type: :integer, null: false),
          MockColumn.new(name: 'created_at', type: :datetime, null: false),
          MockColumn.new(name: 'updated_at', type: :datetime, null: false)
        ]
      end

      def test_timestamps_present_are_not_flagged
        notes = BestPracticesAnalyzer.new(MockModel.new('users', @timestamp_columns)).analyze

        assert_not_includes notes, NoteCodes::NO_TIMESTAMPS
        assert_not_includes notes, NoteCodes::PARTIAL_TS
      end

      def test_missing_timestamps_are_flagged
        columns = [
          MockColumn.new(name: 'id', type: :integer, null: false),
          MockColumn.new(name: 'name', type: :string, null: true)
        ]
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns)).analyze

        assert_includes notes, NoteCodes::NO_TIMESTAMPS
      end

      def test_partial_timestamps_are_flagged
        columns = [
          MockColumn.new(name: 'id', type: :integer, null: false),
          MockColumn.new(name: 'created_at', type: :datetime, null: false)
        ]
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns)).analyze

        assert_includes notes, NoteCodes::PARTIAL_TS
      end

      def test_unindexed_soft_delete_column_is_flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'deleted_at', type: :datetime, null: true)
        ]
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns)).analyze

        assert_includes notes, 'deleted_at:INDEX'
      end

      def test_indexed_soft_delete_column_is_not_flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'deleted_at', type: :datetime, null: true)
        ]
        connection = MockConnection.new([MockIndex.new(columns: ['deleted_at'], unique: false)])
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns, connection)).analyze

        assert_not_includes notes, 'deleted_at:INDEX'
      end

      def test_unindexed_nullable_sti_type_column_is_flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'type', type: :string, null: true)
        ]
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns)).analyze

        assert_includes notes, 'type:INDEX'
        assert_includes notes, 'type:STI_NOT_NULL'
      end

      def test_indexed_not_null_sti_type_column_is_not_flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'type', type: :string, null: false)
        ]
        connection = MockConnection.new([MockIndex.new(columns: ['type'], unique: false)])
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns, connection)).analyze

        assert_not_includes notes, 'type:INDEX'
        assert_not_includes notes, 'type:STI_NOT_NULL'
      end

      def test_text_columns_get_storage_note
        columns = @timestamp_columns + [
          MockColumn.new(name: 'body', type: :text, null: true)
        ]
        notes = BestPracticesAnalyzer.new(MockModel.new('users', columns)).analyze

        assert_includes notes, 'body:STORAGE'
      end
    end
  end
end
