# Refactored Ruby-compatible Settings Implementation

module Lich
  module Common
    require 'sequel'
    # rubocop:disable Lint/RedundantRequireStatement
    require 'set' # Ensure Set is required for Ruby < 3.2, may be removed in future versions
    # rubocop:enable Lint/RedundantRequireStatement

    # settings_proxy.rb is now loaded after Settings module is defined, to allow it to call Settings._log
    # require_relative 'settings/settings_proxy'
    require_relative 'settings/database_adapter'
    require_relative 'settings/path_navigator'

    # Provides a configuration management system for the Lich project.
    # This module handles settings storage, retrieval, and logging.
    # @example Accessing settings
    #   settings = Lich::Common::Settings.root_proxy_for("#{XMLData.game}:#{XMLData.name}")
    module Settings
      # Exception raised for circular references in settings.
      # @example Raising a CircularReferenceError
      #   raise Lich::Common::Settings::CircularReferenceError.new("Custom message")
      class CircularReferenceError < StandardError
        def initialize(msg = "Circular Reference Detected")
          super(msg)
        end
      end

      # Logging Configuration
      LOG_LEVEL_NONE = 0
      LOG_LEVEL_ERROR = 1
      LOG_LEVEL_INFO = 2
      LOG_LEVEL_DEBUG = 3

      @@log_level = LOG_LEVEL_NONE # Default: logging disabled
      @@log_prefix = "[SettingsModule]".freeze

      # Sets the logging level for the Settings module.
      # @param level [Symbol] The desired log level (:none, :error, :info, :debug).
      # @return [Integer] The numeric representation of the log level.
      # @raise [ArgumentError] if an invalid log level is specified.
      # @example Setting log level to debug
      #   Lich::Common::Settings.set_log_level(:debug)
      def self.set_log_level(level)
        numeric_level = case level
                        when :none, LOG_LEVEL_NONE then LOG_LEVEL_NONE
                        when :error, LOG_LEVEL_ERROR then LOG_LEVEL_ERROR
                        when :info, LOG_LEVEL_INFO then LOG_LEVEL_INFO
                        when :debug, LOG_LEVEL_DEBUG then LOG_LEVEL_DEBUG
                        else
                          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "Invalid log level specified: #{level.inspect}. Defaulting to NONE." })
                          LOG_LEVEL_NONE
                        end
        @@log_level = numeric_level
      end

      # Retrieves the current logging level for the Settings module.
      # @return [Integer] The current numeric log level.
      # @example Getting the current log level
      #   current_level = Lich::Common::Settings.get_log_level
      def self.get_log_level
        @@log_level
      end

      # Internal logging method
      # message_proc is a lambda/proc to delay string construction
      # Internal logging method for the Settings module.
      # @param level [Integer] The log level for the message.
      # @param prefix [String] The prefix for the log message.
      # @param message_proc [Proc] A lambda or proc that generates the log message.
      # @return [void]
      # @note This method is intended for internal use only.
      def self._log(level, prefix, message_proc)
        return unless Lich.respond_to?(:log)
        return unless level <= @@log_level

        level_str = case level
                    when LOG_LEVEL_ERROR then "[ERROR]"
                    when LOG_LEVEL_INFO  then "[INFO]"
                    when LOG_LEVEL_DEBUG then "[DEBUG]"
                    else "[UNKNOWN]"
                    end

        begin
          message = message_proc.call
          Lich.log("#{prefix} #{level_str} #{message}")
        rescue => e
          Lich.log("#{prefix} [ERROR] Logging failed: #{e.message} - Original message proc: #{message_proc.source_location if message_proc.respond_to?(:source_location)}")
        end
      end

      # Internal non-destructive correction method (issue from Lich 5.12.6)
      # non-destructive methods (.sort) cannot own a proxy that requires update (.push)
      # Reattaches a proxy to a live object based on the current script context.
      # @param proxy [SettingsProxy] The proxy to reattach.
      # @return [Boolean] Returns true if reattachment was successful, false otherwise.
      # @example Reattaching a proxy
      #   success = Lich::Common::Settings._reattach_live!(my_proxy)
      def self._reattach_live!(proxy)
        script_name = Script.current.name
        scope       = proxy.scope
        path        = proxy.path

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "reattach_live!: scope=#{scope.inspect} path=#{path.inspect}" })

        @path_navigator.reset_path
        @path_navigator.set_path(path)
        live, _root = @path_navigator.navigate_to_path(script_name, true, scope)

        if live.nil?
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "reattach_live!: failed to resolve live target for path=#{path.inspect} scope=#{scope.inspect}" })
          return false
        end

        # Swap the proxy onto the live object via SettingsProxy API (encapsulated)
        # Centralizes invariants/logging within SettingsProxy itself.
        proxy.rebind_to_live!(live)
        true
      end

      @db_adapter = DatabaseAdapter.new(DATA_DIR, :script_auto_settings)
      @path_navigator = PathNavigator.new(@db_adapter)
      @settings_cache = {}
      DEFAULT_SCOPE = ":".freeze
      @safe_navigation_active = false

      # Checks if the given value is a container (Hash or Array).
      # @param value [Object] The value to check.
      # @return [Boolean] True if the value is a container, false otherwise.
      # @example Checking if a value is a container
      #   is_container = Lich::Common::Settings.container?(my_value)
      def self.container?(value)
        value.is_a?(Hash) || value.is_a?(Array)
      end

      # Unwraps any proxies found in the data structure, handling circular references.
      # @param data [Object] The data to unwrap.
      # @param visited [Set] A set of visited object IDs to detect circular references.
      # @return [Object] The unwrapped data.
      # @raise [CircularReferenceError] if a circular reference is detected.
      # @example Unwrapping proxies
      #   unwrapped_data = Lich::Common::Settings.unwrap_proxies(my_data)
      def self.unwrap_proxies(data, visited = Set.new)
        if visited.include?(data.object_id) && (data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(SettingsProxy))
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "unwrap_proxies: Circular reference detected for object_id: #{data.object_id}" })
          raise CircularReferenceError.new("Circular reference detected during unwrap_proxies for object_id: #{data.object_id}")
        end

        visited.add(data.object_id) if data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(SettingsProxy)

        result = case data
                 when SettingsProxy
                   _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "unwrap_proxies: Unwrapping SettingsProxy (target_object_id: #{data.target.object_id})" })
                   unwrap_proxies(data.target, visited)
                 when Hash
                   _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "unwrap_proxies: Unwrapping Hash (object_id: #{data.object_id})" })
                   new_hash = {}
                   data.each do |key, value|
                     new_hash[key] = unwrap_proxies(value, visited)
                   end
                   new_hash
                 when Array
                   _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "unwrap_proxies: Unwrapping Array (object_id: #{data.object_id})" })
                   data.map { |item| unwrap_proxies(item, visited) }
                 else
                   data
                 end

        visited.delete(data.object_id) if data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(SettingsProxy)
        result
      end
      private_class_method :unwrap_proxies

      # Creates a root-level SettingsProxy for the given scope.
      #
      # This factory ensures the proxy directly targets the cached root object
      # for the (script_name, scope) pair. By using the cached root, it avoids
      # "identity drift" bugs where the proxy’s @target differs from the object
      # being persisted by save_proxy_changes.
      #
      # @param scope [String] A logical scope identifier (for example,
      #   "#{XMLData.game}:#{XMLData.name}").
      # @param script_name [String, nil] The script namespace; defaults to
      #   Script.current.name. Pass nil to fall back to the empty string.
      #
      # @return [SettingsProxy] a proxy wrapping the cached root object.
      #
      # @raise [ArgumentError] if scope is nil or empty.
      #
      # @example Create a root proxy for the current character
      #   settings = Lich::Common::Settings.root_proxy_for("#{XMLData.game}:#{XMLData.name}")
      #
      # Creates a root-level SettingsProxy for the given scope.
      # @param scope [String] A logical scope identifier (e.g., "#{XMLData.game}:#{XMLData.name}").
      # @param script_name [String, nil] The script namespace; defaults to Script.current.name.
      # @return [SettingsProxy] A proxy wrapping the cached root object.
      # @raise [ArgumentError] if scope is nil or empty.
      # @example Creating a root proxy
      #   settings_proxy = Lich::Common::Settings.root_proxy_for("#{XMLData.game}:#{XMLData.name}")
      def self.root_proxy_for(scope, script_name: Script.current.name)
        raise ArgumentError, "scope must be a non-empty String" if scope.nil? || scope.to_s.strip.empty?

        script_name ||= ""
        cache_key = "#{script_name}::#{scope}"
        root = @settings_cache[cache_key] ||= @db_adapter.get_settings(script_name, scope)

        SettingsProxy.new(self, scope, [], root)
      end

      # Saves changes made to a SettingsProxy back to the database.
      # @param proxy [SettingsProxy] The proxy containing changes to save.
      # @return [void]
      # @example Saving changes to a proxy
      #   Lich::Common::Settings.save_proxy_changes(my_proxy)
      def self.save_proxy_changes(proxy)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Initiated for proxy.scope: #{proxy.scope.inspect}, proxy.path: #{proxy.path.inspect}, proxy.target_object_id: #{proxy.target.object_id}" })
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: proxy.target data: #{proxy.target.inspect}" })

        path        = proxy.path
        scope       = proxy.scope
        script_name = Script.current.name
        cache_key   = "#{script_name || ""}::#{scope}"

        # Local helper to keep cache in sync with the just-persisted root
        sync_cache = lambda do |root_obj|
          cached = @settings_cache[cache_key]
          if cached && cached.object_id != root_obj.object_id
            if cached.is_a?(Hash) && root_obj.is_a?(Hash)
              cached.replace(root_obj)
            elsif cached.is_a?(Array) && root_obj.is_a?(Array)
              cached.clear
              cached.concat(root_obj)
            else
              @settings_cache[cache_key] = root_obj
            end
          elsif cached.nil?
            @settings_cache[cache_key] = root_obj
          end
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Cache synchronized post-save for #{cache_key}" })
        end

        # --- Refresh-before-save to prevent stale-cache overwrites ---
        fresh_root = @db_adapter.get_settings(script_name, scope)

        cached = @settings_cache[cache_key]
        if cached
          if cached.is_a?(Hash) && fresh_root.is_a?(Hash)
            cached.replace(fresh_root)
            current_root_for_scope = cached
          elsif cached.is_a?(Array) && fresh_root.is_a?(Array)
            cached.clear
            cached.concat(fresh_root)
            current_root_for_scope = cached
          else
            @settings_cache[cache_key] = fresh_root
            current_root_for_scope = fresh_root
          end
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Cache refreshed from DB for #{cache_key} (object_id: #{current_root_for_scope.object_id}): #{current_root_for_scope.inspect}" })
        else
          @settings_cache[cache_key] = fresh_root
          current_root_for_scope = fresh_root
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Cache populated from DB for #{cache_key} (object_id: #{current_root_for_scope.object_id}): #{current_root_for_scope.inspect}" })
        end
        # -------------------------------------------------------------

        # EMPTY PATH → Save *current root* (not proxy.target). Also covers detached "view" proxies.
        if path.empty?
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Empty path; saving CURRENT ROOT for scope #{scope.inspect}" })

          unless current_root_for_scope.is_a?(Hash) || current_root_for_scope.is_a?(Array)
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Root not a container; initializing {} for scope #{scope.inspect}" })
            current_root_for_scope = {}
            @settings_cache[cache_key] = current_root_for_scope
          end

          if proxy.respond_to?(:detached?) && proxy.detached?
            _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Proxy is detached (view); persisting current root without copying view target." })
            save_to_database(current_root_for_scope, scope)
            sync_cache.call(current_root_for_scope)
            return nil
          end

          # Root identity drift: sync proxy.target into cached root if different objects (same-type containers).
          if current_root_for_scope.object_id != proxy.target.object_id
            if proxy.target.is_a?(Hash) && current_root_for_scope.is_a?(Hash)
              _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Root identity mismatch (cache #{current_root_for_scope.object_id} vs proxy #{proxy.target.object_id}); copying via Hash#replace" })
              current_root_for_scope.replace(proxy.target)
            elsif proxy.target.is_a?(Array) && current_root_for_scope.is_a?(Array)
              _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Root identity mismatch (Array); copying elements" })
              current_root_for_scope.clear
              current_root_for_scope.concat(proxy.target)
            else
              _log(LOG_LEVEL_WARN, @@log_prefix, -> { "save_proxy_changes: Root/target type mismatch; persisting current root only (root=#{current_root_for_scope.class}, target=#{proxy.target.class})." })
            end
          end

          save_to_database(current_root_for_scope, scope)
          sync_cache.call(current_root_for_scope)
          return nil
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: script_name: #{script_name.inspect}, cache_key: #{cache_key}" })

        # From here on, we’re saving into a nested path. Ensure root is a container.
        unless current_root_for_scope.is_a?(Hash) || current_root_for_scope.is_a?(Array)
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Root not a container; initializing {} for scope #{scope.inspect}" })
          current_root_for_scope = {}
          @settings_cache[cache_key] = current_root_for_scope
        end

        parent_path = path[0...-1]
        leaf_key    = path.last

        # Pre-navigation diagnostics
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> {
          "save_proxy_changes: Navigation preflight — parent_path=#{parent_path.inspect} (#{parent_path.map { |s| s.class }.inspect}), leaf_key=#{leaf_key.inspect} (#{leaf_key.class}), root_class=#{current_root_for_scope.class}"
        })

        # Navigate **within the freshly-loaded root** (do NOT re-fetch via PathNavigator here).
        begin
          parent = current_root_for_scope
          parent_path.each_with_index do |seg, idx|
            next_seg = parent_path[idx + 1]

            if parent.is_a?(Hash)
              unless parent.key?(seg)
                parent[seg] = next_seg.is_a?(Integer) ? [] : {}
                _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Created #{parent[seg].class} at #{parent_path[0..idx].inspect} for scope #{scope.inspect}" })
              end
              parent = parent[seg]
            elsif parent.is_a?(Array)
              unless seg.is_a?(Integer) && seg >= 0
                _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Non-integer or negative index #{seg.inspect} for Array at #{parent_path[0..idx].inspect} in scope #{scope.inspect}" })
                return nil
              end
              if seg >= parent.length
                (parent.length..seg).each { parent << nil }
                _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Extended Array to index #{seg} at #{parent_path[0..idx].inspect} for scope #{scope.inspect}" })
              end
              parent[seg] ||= (next_seg.is_a?(Integer) ? [] : {})
              parent = parent[seg]
            else
              _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Parent is not a container at #{parent_path[0..idx].inspect} (#{parent.class}) for scope #{scope.inspect}" })
              return nil
            end
          end
        rescue => e
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> {
            "save_proxy_changes: Local navigation raised #{e.class}: #{e.message}. "\
            "scope=#{scope.inspect}, script_name=#{script_name.inspect}, cache_key=#{cache_key}, "\
            "parent_path=#{parent_path.inspect}, leaf_key=#{leaf_key.inspect}"
          })
          bt = (e.backtrace || [])[0, 5]
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Backtrace (top 5): #{bt.join(' | ')}" })
          return nil
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Navigated/created parent (object_id: #{parent.object_id}, class=#{parent.class}): #{parent.inspect}" })

        if parent.is_a?(Hash)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Setting Hash key #{leaf_key.inspect} with proxy.target (object_id: #{proxy.target.object_id})" })
          parent[leaf_key] = proxy.target
        elsif parent.is_a?(Array) && leaf_key.is_a?(Integer)
          if leaf_key < 0
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Negative array index #{leaf_key} not supported at path #{path.inspect} in scope #{scope.inspect}" })
            return nil
          end
          if leaf_key >= parent.length
            (parent.length..leaf_key).each { parent << nil }
            _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Extended Array to index #{leaf_key} for parent at path #{parent_path.inspect}" })
          end
          parent[leaf_key] = proxy.target
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Set Array index #{leaf_key} with proxy.target (object_id: #{proxy.target.object_id})" })
        else
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> {
            "save_proxy_changes: Cannot set value at path #{path.inspect} in scope #{scope.inspect}; "\
            "parent_class=#{parent.class}, leaf_key_class=#{leaf_key.class}"
          })
          return nil
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: root after update (object_id: #{current_root_for_scope.object_id}): #{current_root_for_scope.inspect}" })
        save_to_database(current_root_for_scope, scope)
        sync_cache.call(current_root_for_scope)
      end

      # Retrieves the current settings for the active script and scope.
      # @param scope [String] The scope for which to retrieve settings; defaults to DEFAULT_SCOPE.
      # @return [Object] The current settings data.
      # @example Getting current script settings
      #   settings = Lich::Common::Settings.current_script_settings
      def self.current_script_settings(scope = DEFAULT_SCOPE)
        script_name = Script.current.name
        cache_key = "#{script_name || ""}::#{scope}" # Use an empty string if script_name is nil
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "current_script_settings: Request for scope: #{scope.inspect}, cache_key: #{cache_key}" })

        cached_data = @settings_cache[cache_key]
        if cached_data
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Cache hit for #{cache_key} (object_id: #{cached_data.object_id}). Returning DUP: #{cached_data.inspect}" })
          return cached_data.dup
        else
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Cache miss for #{cache_key}. Loading from DB." })
          settings = @db_adapter.get_settings(script_name, scope)
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Loaded from DB (object_id: #{settings.object_id}): #{settings.inspect}" })
          @settings_cache[cache_key] = settings
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Stored in cache (object_id: #{@settings_cache[cache_key].object_id}). Returning DUP." })
          return settings.dup
        end
      end

      # Saves the provided data to the database for the current script and scope.
      # @param data_to_save [Object] The data to save.
      # @param scope [String] The scope for which to save data; defaults to DEFAULT_SCOPE.
      # @return [void]
      # @example Saving data to the database
      #   Lich::Common::Settings.save_to_database(my_data)
      def self.save_to_database(data_to_save, scope = DEFAULT_SCOPE)
        script_name = Script.current.name

        if script_name.nil? || script_name.empty?
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_to_database: Aborting save. Script.current.name is nil or empty. Scope: #{scope.inspect}. Data will NOT be persisted." })
          return nil # Explicitly return nil
        end

        cache_key = "#{script_name}::#{scope}" # script_name is guaranteed to be non-nil/non-empty here
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_to_database: Saving for script: '#{script_name}', scope: #{scope.inspect}, cache_key: #{cache_key}" })
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_to_database: Data BEFORE unwrap_proxies (object_id: #{data_to_save.object_id}): #{data_to_save.inspect}" })

        unwrapped_settings = unwrap_proxies(data_to_save)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_to_database: Data AFTER unwrap_proxies (object_id: #{unwrapped_settings.object_id}): #{unwrapped_settings.inspect}" })

        @db_adapter.save_settings(script_name, unwrapped_settings, scope)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_to_database: Data saved to DB for script '#{script_name}'." })

        @settings_cache[cache_key] = unwrapped_settings
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_to_database: Cache updated for #{cache_key} with saved data (object_id: #{@settings_cache[cache_key].object_id})." })
      end

      # Refreshes the settings data for the specified scope, clearing the cache.
      # @param scope [String] The scope to refresh; defaults to DEFAULT_SCOPE.
      # @return [Object] The refreshed settings data.
      # @example Refreshing settings data
      #   refreshed_settings = Lich::Common::Settings.refresh_data
      def self.refresh_data(scope = DEFAULT_SCOPE)
        script_name = Script.current.name
        cache_key = "#{script_name || ""}::#{scope}" # Use an empty string if script_name is nil
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "refresh_data: Deleting cache for scope: #{scope.inspect}, cache_key: #{cache_key}" })
        @settings_cache.delete(cache_key)
        current_script_settings(scope)
      end

      # Resets the path navigator and returns the specified value.
      # @param value [Object] The value to return after resetting the path.
      # @return [Object] The value passed in.
      # @example Resetting path and returning a value
      #   returned_value = Lich::Common::Settings.reset_path_and_return(my_value)
      def self.reset_path_and_return(value)
        @path_navigator.reset_path_and_return(value)
      end

      # Navigates to a specific path within the current settings structure.
      # @param create_missing [Boolean] Whether to create missing segments; defaults to true.
      # @param scope [String] The scope for navigation; defaults to DEFAULT_SCOPE.
      # @return [Array] An array containing the target object and the root object.
      # @example Navigating to a path
      #   target, root = Lich::Common::Settings.navigate_to_path
      def self.navigate_to_path(create_missing = true, scope = DEFAULT_SCOPE)
        root_for_scope = current_script_settings(scope)
        return [root_for_scope, root_for_scope] if @path_navigator.path.empty?

        target = root_for_scope
        @path_navigator.path.each do |key|
          if target.is_a?(Hash) && target.key?(key)
            target = target[key]
          elsif target.is_a?(Array) && key.is_a?(Integer) && key >= 0 && key < target.length
            target = target[key]
          elsif create_missing && (target.is_a?(Hash) || target.is_a?(Array))
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "navigate_to_path: Creating missing segment '#{key}' in DUPPED structure for scope #{scope.inspect}" })
            new_node = key.is_a?(Integer) ? [] : {}
            if target.is_a?(Hash)
              target[key] = new_node
            elsif target.is_a?(Array) && key.is_a?(Integer)
              target[key] = new_node
            end
            target = new_node
          else
            return [nil, root_for_scope]
          end
        end
        [target, root_for_scope]
      end

      # Sets a specific setting for the current script and scope.
      # @param scope [String] The scope in which to set the value; defaults to DEFAULT_SCOPE.
      # @param name [String] The name of the setting to set.
      # @param value [Object] The value to assign to the setting.
      # @return [void]
      # @example Setting a script setting
      #   Lich::Common::Settings.set_script_settings("my_scope", "my_setting", "my_value")
      def self.set_script_settings(scope = DEFAULT_SCOPE, name, value)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: scope: #{scope.inspect}, name: #{name.inspect}, value: #{value.inspect}, current_path: #{@path_navigator.path.inspect}" })
        unwrapped_value = unwrap_proxies(value)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: unwrapped_value: #{unwrapped_value.inspect}" })

        current_root = current_script_settings(scope)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: current_root (DUP) for scope #{scope.inspect} (object_id: #{current_root.object_id}): #{current_root.inspect}" })

        if @path_navigator.path.empty?
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: Path is empty. Setting '#{name}' on current_root." })
          current_root[name] = unwrapped_value
          save_to_database(current_root, scope)
        else
          if !@path_navigator.path.empty?
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "set_script_settings: WARNING: Called with non-empty path_navigator path: #{@path_navigator.path.inspect}. This is unusual for Char/GameSettings direct assignment." })
          end
          if current_root.is_a?(Hash)
            current_root[name] = unwrapped_value
            save_to_database(current_root, scope)
          else
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "set_script_settings: current_root for scope #{scope.inspect} is not a Hash. Cannot set key '#{name}'. Root class: #{current_root.class}" })
          end
        end
        reset_path_and_return(value)
      end

      # Retrieves a setting by name for the current script and scope.
      # @param name [String] The name of the setting to retrieve.
      # @return [Object] The value of the setting, or nil if not found.
      # @example Accessing a setting
      #   value = Lich::Common::Settings["my_setting"]
      def self.[](name)
        scope_to_use = DEFAULT_SCOPE
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[]: name: #{name.inspect}, current_path: #{@path_navigator.path.inspect}, safe_nav: #{@safe_navigation_active}" })

        if @path_navigator.path.empty?
          data_for_scope = current_script_settings(scope_to_use)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (top-level): data_for_scope (DUP) (object_id: #{data_for_scope.object_id}): #{data_for_scope.inspect}" })
          value = get_value_from_container(data_for_scope, name)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (top-level): value for '#{name}': #{value.inspect}" })
          if value.nil? && !data_for_scope.is_a?(Array) && (!data_for_scope.is_a?(Hash) || !data_for_scope.key?(name))
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.[] (top-level): Key '#{name}' not found or value is nil. Activating safe_navigation." })
            @safe_navigation_active = true
          end
          return reset_path_and_return(wrap_value_if_container(value, scope_to_use, [name]))
        else
          current_target, _ = navigate_to_path(false, scope_to_use)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (path-based): current_target: #{current_target.inspect}" })
          value = get_value_from_container(current_target, name)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (path-based): value for '#{name}': #{value.inspect}" })
          new_path = @path_navigator.path + [name]
          if value.nil? && !current_target.is_a?(Array) && (!current_target.is_a?(Hash) || !current_target.key?(name))
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.[] (path-based): Key '#{name}' not found or value is nil in path. Activating safe_navigation." })
            @safe_navigation_active = true
          end
          return reset_path_and_return(wrap_value_if_container(value, scope_to_use, new_path))
        end
      end

      # Sets a value for a specific setting by name for the current script and scope.
      # @param name [String] The name of the setting to set.
      # @param value [Object] The value to assign to the setting.
      # @return [void]
      # @example Setting a value
      #   Lich::Common::Settings["my_setting"] = "new_value"
      def self.[]=(name, value)
        scope_to_use = DEFAULT_SCOPE
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[]=: name: #{name.inspect}, value: #{value.inspect}, current_path: #{@path_navigator.path.inspect}" })
        @safe_navigation_active = false # Reset safe navigation on assignment

        if @path_navigator.path.empty?
          set_script_settings(scope_to_use, name, value)
        else
          target, root_settings = navigate_to_path(true, scope_to_use)
          if target && (target.is_a?(Hash) || target.is_a?(Array))
            actual_value = value.is_a?(SettingsProxy) ? unwrap_proxies(value) : value
            target[name] = actual_value
            save_to_database(root_settings, scope_to_use)
            reset_path_and_return(value)
          else
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "Settings.[]=: Cannot assign to non-container or nil target at path #{@path_navigator.path.inspect}" })
            reset_path_and_return(nil)
          end
        end
      end

      # Retrieves a setting value for a specific scope and key.
      # @param scope_string [String] The scope to search within.
      # @param key_name [String] The key of the setting to retrieve.
      # @return [Object] The value of the setting, or nil if not found.
      # @example Getting a scoped setting
      #   value = Lich::Common::Settings.get_scoped_setting("my_scope", "my_key")
      def self.get_scoped_setting(scope_string, key_name)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "get_scoped_setting: scope: #{scope_string.inspect}, key: #{key_name.inspect}" })
        data_for_scope = current_script_settings(scope_string)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "get_scoped_setting: data_for_scope (DUP) (object_id: #{data_for_scope.object_id}): #{data_for_scope.inspect}" })
        value = get_value_from_container(data_for_scope, key_name)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "get_scoped_setting: value for '#{key_name}': #{value.inspect}" })

        if value.nil? && key_name
          key_absent_in_hash = data_for_scope.is_a?(Hash) && !data_for_scope.key?(key_name)
          key_invalid_for_array = data_for_scope.is_a?(Array) && (!key_name.is_a?(Integer) || key_name < 0 || key_name >= data_for_scope.length)

          if key_absent_in_hash || key_invalid_for_array || (data_for_scope.nil? || (data_for_scope.is_a?(Hash) && data_for_scope.empty?))
            _log(Settings::LOG_LEVEL_INFO, @@log_prefix, -> { "get_scoped_setting: Key '#{key_name}' not found in scope '#{scope_string}'. Value will be nil, supporting '|| default' idiom." })
          end
        end
        wrap_value_if_container(value, scope_string, key_name ? [key_name] : [])
      end

      # Wraps a value in a SettingsProxy if it is a container (Hash or Array).
      # @param value [Object] The value to potentially wrap.
      # @param scope [String] The scope for the value.
      # @param path_array [Array] The path to the value.
      # @return [Object] The wrapped value or the original value if not a container.
      # @example Wrapping a value
      #   wrapped_value = Lich::Common::Settings.wrap_value_if_container(my_value, "my_scope", ["my_key"])
      def self.wrap_value_if_container(value, scope, path_array)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "wrap_value_if_container: value_class: #{value.class}, scope: #{scope.inspect}, path: #{path_array.inspect}" })
        if container?(value)
          proxy = SettingsProxy.new(self, scope, path_array, value)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "wrap_value_if_container: Wrapped in proxy: #{proxy.inspect}" })
          return proxy
        else
          return value
        end
      end

      # Converts the current settings to a hash representation.
      # @param scope [String] The scope to convert; defaults to DEFAULT_SCOPE.
      # @return [Hash] A hash representation of the current settings.
      # @example Converting settings to hash
      #   settings_hash = Lich::Common::Settings.to_hash
      def self.to_hash(scope = DEFAULT_SCOPE)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "to_hash: scope: #{scope.inspect}" })
        data = current_script_settings(scope)
        unwrapped_data = unwrap_proxies(data)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "to_hash: Returning unwrapped data (snapshot): #{unwrapped_data.inspect}" })
        return unwrapped_data
      end

      # Legacy Support Methods
      # Legacy method for saving settings; does nothing.
      # @return [Symbol] Returns :noop.
      # @example Calling save
      #   result = Lich::Common::Settings.save
      def self.save
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.save called (legacy no-op)." })
        :noop
      end

      # Legacy method for loading settings; aliases to refresh_data.
      # @return [void]
      # @example Calling load
      #   Lich::Common::Settings.load
      def self.load
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.load called (legacy, aliasing to refresh_data)." })
        refresh_data
      end

      # Legacy method for converting settings to hash; aliases to to_hash.
      # @param scope [String] The scope to convert; defaults to DEFAULT_SCOPE.
      # @return [Hash] A hash representation of the current settings.
      # @example Calling to_h
      #   settings_hash = Lich::Common::Settings.to_h
      def self.to_h(scope = DEFAULT_SCOPE) # Added scope to match to_hash for consistency if used directly
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.to_h called (legacy, aliasing to to_hash)." })
        self.to_hash(scope)
      end

      # Deprecated No-Op Methods from Original
      # Deprecated no-op method for saving all settings.
      # @return [nil]
      # @example Calling save_all
      #   Lich::Common::Settings.save_all
      def self.save_all
        Lich.deprecated('Settings.save_all', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.save_all called (legacy deprecated no-op)." })
        nil
      end

      # Deprecated no-op method for clearing settings.
      # @return [nil]
      # @example Calling clear
      #   Lich::Common::Settings.clear
      def self.clear
        Lich.deprecated('Settings.clear', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.clear called (legacy deprecated no-op)." })
        nil
      end

      # Deprecated no-op method for setting auto configuration.
      # @param _val [Object] The value to set.
      # @return [nil]
      # @example Setting auto
      #   Lich::Common::Settings.auto = true
      def self.auto=(_val)
        Lich.deprecated('Settings.auto=(val)', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.auto= called (legacy deprecated no-op)." })
      end

      # Deprecated no-op method for getting auto configuration.
      # @return [nil]
      # @example Getting auto
      #   auto_value = Lich::Common::Settings.auto
      def self.auto
        Lich.deprecated('Settings.auto', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.auto called (legacy deprecated no-op)." })
        nil
      end

      # Deprecated no-op method for autoloading settings.
      # @return [nil]
      # @example Calling autoload
      #   Lich::Common::Settings.autoload
      def self.autoload
        Lich.deprecated('Settings.autoload', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.autoload called (legacy deprecated no-op)." })
        nil
      end
      # End Legacy Support Methods

      # Handles missing methods by delegating to the path navigator.
      # @param method [Symbol] The method that was called.
      # @param args [Array] The arguments passed to the method.
      # @return [Object] The result of the delegated method call or nil.
      # @example Handling missing methods
      #   Lich::Common::Settings.some_missing_method
      def self.method_missing(method, *args, &block)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "method_missing: method: #{method}, args: #{args.inspect}, path: #{@path_navigator.path.inspect}" })
        if @safe_navigation_active && !@path_navigator.path.empty?
          if method.to_s.end_with?("=")
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "method_missing: Attempted assignment (#{method}) on a nil path due to safe navigation." })
            return reset_path_and_return(nil)
          end
          return reset_path_and_return(nil)
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "method_missing: Delegating to path_navigator: #{method}" })
        @path_navigator.send(method, *args, &block)
      end

      # Checks if the Settings module responds to a missing method.
      # @param method_name [Symbol] The name of the method.
      # @param include_private [Boolean] Whether to include private methods.
      # @return [Boolean] True if the method is handled, false otherwise.
      def self.respond_to_missing?(method_name, include_private = false)
        @path_navigator.respond_to?(method_name, include_private) || super
      end

      # Retrieves a value from a container (Hash or Array) based on the key.
      # @param container [Object] The container to retrieve the value from.
      # @param key [Object] The key to look up in the container.
      # @return [Object] The value found, or nil if not found.
      # @example Getting a value from a container
      #   value = Lich::Common::Settings.get_value_from_container(my_hash, "my_key")
      def self.get_value_from_container(container, key)
        if container.is_a?(Hash)
          container[key]
        elsif container.is_a?(Array) && key.is_a?(Integer)
          container[key]
        elsif container.is_a?(Array) && !key.is_a?(Integer)
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "get_value_from_container: Attempted to access Array with non-Integer key: #{key.inspect}" })
          nil
        else
          nil
        end
      end
    end
  end
end

require_relative 'settings/settings_proxy'
