# frozen_string_literal: true

module RailsLens
  # Compact note codes for LLM-readable annotations
  # Format: "column_name:CODE" or "association:CODE"
  module NoteCodes
    # Column constraint codes
    NOT_NULL = 'NOT_NULL'
    DEFAULT = 'DEFAULT'
    LIMIT = 'LIMIT'

    # Index codes
    INDEX = 'INDEX'
    POLY_INDEX = 'POLY_INDEX'
    COMP_INDEX = 'COMP_INDEX'
    REDUND_IDX = 'REDUND_IDX'

    # Type codes
    USE_DECIMAL = 'USE_DECIMAL'
    USE_INTEGER = 'USE_INTEGER'

    # Association codes
    INVERSE_OF = 'INVERSE_OF'
    N_PLUS_ONE = 'N_PLUS_ONE'
    COUNTER_CACHE = 'COUNTER_CACHE'
    FK_CONSTRAINT = 'FK_CONSTRAINT'

    # Best practices codes
    NO_TIMESTAMPS = 'NO_TIMESTAMPS'
    PARTIAL_TS = 'PARTIAL_TS'
    STORAGE = 'STORAGE'

    # STI codes
    STI_INDEX = 'STI_INDEX'
    STI_NOT_NULL = 'STI_NOT_NULL'

    # View codes
    VIEW_READONLY = 'VIEW_READONLY'
    ADD_READONLY = 'ADD_READONLY'
    MATVIEW_STALE = 'MATVIEW_STALE'
    ADD_REFRESH = 'ADD_REFRESH'
    NESTED_VIEW = 'NESTED_VIEW'
    VIEW_PROTECT = 'VIEW_PROTECT'

    # Structure codes
    MISSING = 'MISSING'
    DEPTH_CACHE = 'DEPTH_CACHE'

    class << self
      # Build a compact note string
      # @param subject [String, nil] column/association name (nil for model-level)
      # @param code [String] note code constant
      # @return [String] formatted note
      def note(subject, code)
        subject ? "#{subject}:#{code}" : code
      end
    end
  end
end
