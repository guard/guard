require "guard/plugin/base"

module Guard
  unless ENV["GUARD_GEM_SILENCE_DEPRECATIONS"] == "1"

    UPGRADE_WIKI_URL =
      "https://github.com/guard/guard/"  +
      "wiki/Upgrading-to-Guard-2.0#changes-in-guardguard"

    STDERR.puts <<-EOS

    ******** BIG DEPRECATION WARNING !! ********

    Hi, Guard here.

    You're including lib/guard/guard.rb ...

    ... which contains code deprecated over a year ago!


    This file will likely be removed in the next version, so make sure you're
    not requiring it anywhere to ensure safe gem upgrades.

    If this message is annoying and you can't quickly fix the issue (see below),
    you have 2 options:

      1) Simply set the env variable "GUARD_GEM_SILENCE_DEPRECATIONS" to "1" to
      skip this message

      2) Freeze the gem to a previous version (not recommended because upgrades
      are cool and you might forget to unfreeze later!).

      E.g. in your Gemfile:

        if Time.now > Time.new(2014,11,10)
          gem 'guard', '~> 2.8'
        else
          # Freeze until 2014-11-10 - in case we forget to change back ;)
          gem 'guard', '= 2.7.3'
        end

    If you don't know which gem or plugin is requiring this file, here's a
    backtrace:

    #{Thread.current.backtrace[1..5].join("\n\t >> ")}"

    Here's how to quickly upgrade/fix this (given you are a maintainer of the
    offending plugin or you want to prepare a pull request yourself):

      #{UPGRADE_WIKI_URL}

    Have fun!

    ******** END OF DEPRECATION MESSAGE ********

    EOS

  end
end

module Guard
  # @deprecated Inheriting from `Guard::Guard` is deprecated, please inherit
  #   from {Plugin} instead. Please note that the constructor signature has
  #   changed from `Guard::Guard#initialize(watchers = [], options = {})` to
  #   `Guard::Plugin#initialize(options = {})`.
  #
  # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
  #   upgrade for Guard 2.0
  #
  class Guard
    include ::Guard::Plugin::Base

    # @deprecated Inheriting from `Guard::Guard` is deprecated, please inherit
    #   from {Plugin} instead. Please note that the constructor signature
    #   has changed from `Guard::Guard#initialize(watchers = [], options = {})`
    #   to `Guard::Plugin#initialize(options = {})`.
    #
    # Initializes a Guard plugin. Don't do any work here,
    #   especially as Guard plugins get initialized even if they are not in an
    #   active group!
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    # @param [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @param [Hash] options the custom Guard plugin options
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from
    #   a watcher
    # @option options [Boolean] first_match stop after the first watcher that
    #   returns a valid result
    #
    def initialize(watchers = [], options = {})
      UI.deprecation(Deprecator::GUARD_GUARD_DEPRECATION % title)

      _set_instance_variables_from_options(options.merge(watchers: watchers))
      _register_callbacks
    end
  end
end
