# frozen_string_literal: true

require "shellany/sheller"

module Guard
  class Terminal
    class << self
      def clear
        cmd = Gem.win_platform? ? "cls" : "printf '\33c\e[3J';"
        exit_code, _, stderr = Shellany::Sheller.system(cmd)
        fail Errno::ENOENT, stderr unless exit_code.zero?
      end
    end
  end
end
