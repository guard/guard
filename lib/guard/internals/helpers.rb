# frozen_string_literal: true

module Guard
  # @private api
  module Internals
    module Helpers
      def _relative_pathnames(paths)
        paths.map { |path| _relative_pathname(path) }
      end

      def _relative_pathname(path)
        full_path = Pathname(path)
        full_path.relative_path_from(Pathname.pwd)
      rescue ArgumentError
        full_path
      end
    end
  end
end
