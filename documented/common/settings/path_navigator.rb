# frozen_string_literal: true

module Lich
  module Common
    # Path navigator to encapsulate path navigation logic
    # Path navigator to encapsulate path navigation logic
    #
    # This class provides methods to manage and navigate through a path structure.
    # It interacts with a database adapter to retrieve and manipulate settings.
    # @example Creating a path navigator
    #   navigator = Lich::Common::PathNavigator.new(db_adapter)
    class PathNavigator
      def initialize(db_adapter)
        @db_adapter = db_adapter
        @path = []
      end

      attr_reader :path

      # Allow external callers to drive the effective path
      # Allow external callers to drive the effective path
      #
      # This method sets the current path to the provided new path.
      # @param new_path [Array, Object] The new path to set, can be an array or a single object.
      # @return [void]
      # @example Setting a new path
      #   navigator.set_path(["level1", "level2"])
      def set_path(new_path)
        @path = Array(new_path).dup
      end

      # Resets the current path to an empty state.
      #
      # This method clears the existing path.
      # @return [void]
      # @example Resetting the path
      #   navigator.reset_path
      def reset_path
        @path = []
      end

      # Resets the path and returns a specified value.
      #
      # This method clears the current path and returns the provided value.
      # @param value [Object] The value to return after resetting the path.
      # @return [Object] The provided value.
      # @example Resetting the path and returning a value
      #   result = navigator.reset_path_and_return("default")
      def reset_path_and_return(value)
        reset_path
        value
      end

      # Navigate to the node at "path" (or @path if nil).
      # Returns [target, root]
      #
      # @param script_name [String] the script namespace (e.g., Script.current.name)
      # @param create_missing [Boolean] whether to create intermediate containers
      # @param scope [String] settings scope (e.g., "GS3:CharName")
      # @param path [Array, nil] path segments; integers index arrays, symbols/strings index hashes
      #
      # @return [Array(Object, Hash|Array)] [target_node, root_object]
      # Navigate to the node at "path" (or @path if nil).
      # Returns [target, root]
      #
      # This method navigates through the path segments to find the target node.
      # It can create missing containers if specified.
      # @param script_name [String] the script namespace (e.g., Script.current.name)
      # @param create_missing [Boolean] whether to create intermediate containers
      # @param scope [String] settings scope (e.g., "GS3:CharName")
      # @param path [Array, nil] path segments; integers index arrays, symbols/strings index hashes
      # @return [Array(Object, Hash|Array)] [target_node, root_object]
      # @raise ArgumentError if an invalid array index is encountered
      # @example Navigating to a path
      #   target, root = navigator.navigate_to_path("my_script", true, "GS3:CharName", ["level1", "level2"])
      def navigate_to_path(script_name, create_missing = true, scope = ":", path = nil)
        work_path = path ? Array(path) : @path
        root = @db_adapter.get_settings(script_name, scope)
        return [root, root] if work_path.empty?

        target = root
        work_path.each_with_index do |key, idx|
          next_key = work_path[idx + 1]

          if target.is_a?(Hash)
            if target.key?(key)
              target = target[key]
            elsif create_missing
              target[key] = next_key.is_a?(Integer) ? [] : {}
              target = target[key]
            else
              return [nil, root]
            end

          elsif target.is_a?(Array)
            unless key.is_a?(Integer) && key >= 0
              return [nil, root] unless create_missing
              raise ArgumentError, "Array index must be a non-negative Integer (got: #{key.inspect})"
            end

            if key >= target.length
              (target.length..key).each { target << nil }
            end

            if target[key].nil? && create_missing
              target[key] = next_key.is_a?(Integer) ? [] : {}
            end
            return [nil, root] if target[key].nil? && !create_missing
            target = target[key]

          else
            # Non-container encountered mid-path; only replace if allowed.
            return [nil, root] unless create_missing
            replacement = next_key.is_a?(Integer) ? [] : {}
            target = replacement
          end
        end

        [target, root]
      end
    end
  end
end
