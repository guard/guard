module Guard

  # Simple interactor that that reads user
  # input from standard input.
  #
  class SimpleInteractor < Interactor

    # Read a line from stdin with Readline.
    #
    def read_line
      while line = $stdin.gets
        process_input(line.gsub(/^\W*/, '').chomp)
      end
    end

  end
end
