# frozen_string_literal: true

require "shellany/sheller"

module Guard
  # @private
  class Terminal
    class << self
      def clear
        cmd = Gem.win_platform? ? "cls" : "printf '\33c\e[3J';"
        stat, _, stderr = Shellany::Sheller.system(cmd)
        fail Errno::ENOENT, stderr unless stat.success?
      end
    end
  end
end
