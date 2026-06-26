# frozen_string_literal: true

module RailsLens
  # Small helpers for emitting TOML fragments used throughout annotation output.
  module TomlFormat
    module_function

    # Format an array of values as a TOML inline array of quoted strings:
    #   quoted_array(["a", "b"]) => %(["a", "b"])
    def quoted_array(values)
      "[#{values.map { |v| "\"#{v}\"" }.join(', ')}]"
    end
  end
end
