## hot module reloading
module Lich
  # Common functionality for the Lich project
  # This module contains methods for hot module reloading.
  # @example Using the HMR module
  #   Lich::Common::HMR.reload(/my_pattern/)
  module Common
    # Hot Module Reloading functionality
    # This module provides methods to clear cache, reload files, and send messages.
    # @example Reloading a module
    #   Lich::Common::HMR.reload(/my_module/)
    module HMR
      # Clears the gem load paths cache
      # @return [void] This method does not return a value.
      # @example Clearing the cache
      #   Lich::Common::HMR.clear_cache
      def self.clear_cache
        Gem.clear_paths
      end

      # Sends a message to the appropriate output
      # @param message [String] The message to be sent
      # @return [void] This method does not return a value.
      # @example Sending a message
      #   Lich::Common::HMR.msg("Hello, World!")
      # @note If the message contains HTML tags, it will be handled differently.
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Returns a list of loaded Ruby files
      # @return [Array<String>] An array of loaded Ruby file paths.
      # @example Getting loaded files
      #   loaded_files = Lich::Common::HMR.loaded
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads files matching the given pattern
      # @param pattern [Regexp] The regex pattern to match file paths
      # @return [void] This method does not return a value.
      # @raise [LoadError] If a file cannot be loaded
      # @example Reloading files
      #   Lich::Common::HMR.reload(/my_pattern/)
      # @note This method clears the cache before reloading.
      def self.reload(pattern)
        self.clear_cache
        loaded_paths = self.loaded.grep(pattern)
        unless loaded_paths.empty?
          loaded_paths.each { |file|
            begin
              load(file)
              self.msg "<b>[lich.hmr] reloaded %s</b>" % file
            rescue => exception
              self.msg exception
              self.msg exception.backtrace.join("\n")
            end
          }
        else
          self.msg "<b>[lich.hmr] nothing matching regex pattern: %s</b>" % pattern.source
        end
      end
    end
  end
end
