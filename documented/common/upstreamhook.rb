# Carve out from lich.rbw
# UpstreamHook class 2024-06-13

module Lich
  module Common
    # Handles upstream hooks for the Lich project.
    # This class allows adding, running, removing, and listing hooks that can modify client strings.
    # @example Adding a hook
    #   UpstreamHook.add("example_hook", Proc.new { |str| str.upcase })
    class UpstreamHook
      # A class variable that stores the registered upstream hooks.
      @@upstream_hooks ||= Hash.new
      # A class variable that stores the sources of the registered upstream hooks.
      @@upstream_hook_sources ||= Hash.new

      # Adds a new upstream hook.
      # @param name [String] The name of the hook.
      # @param action [Proc] The action to be executed when the hook is run.
      # @return [Boolean] Returns true if the hook was added successfully, false otherwise.
      # @raise [StandardError] Raises an error if action is not a Proc.
      # @example Adding a hook
      #   UpstreamHook.add("example_hook", Proc.new { |str| str.upcase })
      def UpstreamHook.add(name, action)
        unless action.is_a?(Proc)
          echo "UpstreamHook: not a Proc (#{action})"
          return false
        end
        @@upstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@upstream_hooks[name] = action
      end

      # Runs all registered upstream hooks in order.
      # @param client_string [String] The string to be modified by the hooks.
      # @return [String, nil] Returns the modified string or nil if any hook returns nil.
      # @raise [StandardError] Catches exceptions from hook actions and removes the faulty hook.
      # @example Running hooks
      #   modified_string = UpstreamHook.run("input string")
      def UpstreamHook.run(client_string)
        for key in @@upstream_hooks.keys
          begin
            client_string = @@upstream_hooks[key].call(client_string)
          rescue
            @@upstream_hooks.delete(key)
            respond "--- Lich: UpstreamHook: #{$!}"
            respond $!.backtrace.first
          end
          return nil if client_string.nil?
        end
        return client_string
      end

      # Removes an upstream hook by name.
      # @param name [String] The name of the hook to remove.
      # @return [void] This method does not return a value.
      # @example Removing a hook
      #   UpstreamHook.remove("example_hook")
      def UpstreamHook.remove(name)
        @@upstream_hook_sources.delete(name)
        @@upstream_hooks.delete(name)
      end

      # Lists all registered upstream hooks.
      # @return [Array<String>] An array of hook names.
      # @example Listing hooks
      #   hooks = UpstreamHook.list
      def UpstreamHook.list
        @@upstream_hooks.keys.dup
      end

      # Displays the sources of all registered upstream hooks in a table format.
      # @return [String] A formatted string representation of the hook sources.
      # @example Displaying hook sources
      #   UpstreamHook.sources
      def UpstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@upstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Retrieves the hash of upstream hook sources.
      # @return [Hash<String, String>] A hash mapping hook names to their sources.
      # @example Getting hook sources
      #   sources = UpstreamHook.hook_sources
      def UpstreamHook.hook_sources
        @@upstream_hook_sources
      end
    end
  end
end
