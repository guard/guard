require "guard/deprecated_methods"

# TODO: deprecate this whole file

module Guard
  unless ENV["GUARD_GEM_SILENCE_DEPRECATIONS"] == "1"
    UPGRADE_WIKI_URL =
      "https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0"

    STDERR.puts <<-EOS
    You are including "guard/guardfile.rb", which has been deprecated since
    2013 ... and will be removed.

    Migration is easy, see: #{UPGRADE_WIKI_URL}

    Sorry for the inconvenience and have a nice day!
    EOS
  end
  module Guardfile
    extend DeprecatedMethods::Guardfile::ClassMethods
  end
end
