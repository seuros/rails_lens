# frozen_string_literal: true

module RailsLens
  module Schema
    # Shared file-based annotation removal. Host classes must provide a
    # +#model_file_path+ method returning the file to clean.
    module AnnotationRemoval
      def remove_annotations(file_path = nil)
        file_path ||= model_file_path
        return unless file_path && File.exist?(file_path)

        content = File.read(file_path)
        cleaned_content = Annotation.remove(content)

        if cleaned_content == content
          false
        else
          File.write(file_path, cleaned_content)
          true
        end
      end
    end
  end
end
