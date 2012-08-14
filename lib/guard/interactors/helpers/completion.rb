require 'guard'

module Guard
  
  # Module for providing word completion to an interactor.
  #
  module CompletionHelper

    COMPLETION_ACTIONS = %w[help reload exit pause notification show]
    
    # Auto complete the given word.
    #
    # @param [String] word the partial word
    # @return [Array<String>] the matching words
    #
    def auto_complete(word)
      completion_list.grep(/^#{ Regexp.escape(word) }/)
    end

    # Get the auto completion list.
    #
    # @return [Array<String>] the list of words
    #
    def completion_list
      groups = ::Guard.groups.map { |group| group.name.to_s }
      guards = ::Guard.guards.map { |guard| guard.class.to_s.downcase.sub('guard::', '') }

      COMPLETION_ACTIONS + groups + guards - ['default']
    end
    
  end
end