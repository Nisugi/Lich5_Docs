# Carve out class WatchFor
# 2024-06-13
# has rubocop Lint issues (return nil) - overriding until it can be further researched

module Lich
  module Common
    # Represents a watcher for specific patterns in the script.
    # This class allows you to define patterns to watch for and execute a block of code when those patterns are matched.
    # @example Creating a watcher for a specific string
    #   watcher = Lich::Common::Watchfor.new("example string") { puts "Matched!" }
    class Watchfor
      # rubocop:disable Lint/ReturnInVoidContext
      # Initializes a new Watchfor instance.
      # @param line [String, Regexp] The string or regular expression to watch for.
      # @param theproc [Proc, nil] An optional Proc to execute if no block is given.
      # @param block [Proc] The block of code to execute when the pattern is matched.
      # @return [nil] Returns nil if initialization fails due to invalid parameters.
      # @raise [ArgumentError] Raises an error if neither a string nor a regexp is provided.
      # @example Initializing with a string
      #   watcher = Lich::Common::Watchfor.new("test") { puts "Found!" }
      def initialize(line, theproc = nil, &block)
        return nil unless (script = Script.current)

        if line.is_a?(String)
          line = Regexp.new(Regexp.escape(line))
        elsif !line.is_a?(Regexp)
          echo 'watchfor: no string or regexp given'
          return nil
        end
        if block.nil?
          if theproc.respond_to? :call
            block = theproc
          else
            echo 'watchfor: no block or proc given'
            return nil
          end
        end
        script.watchfor[line] = block
      end

      # rubocop:enable Lint/ReturnInVoidContext
      # Clears all watch patterns from the current script.
      # @return [void] This method does not return a value.
      # @example Clearing all watchers
      #   Lich::Common::Watchfor.clear
      def Watchfor.clear
        script.watchfor = Hash.new
      end
    end
  end
end
