module Lich
  module Common
    # SettingsProxy is defined here but relies on Settings module being fully defined first,
    # especially Settings._log. The actual require_relative for settings_proxy.rb
    # is now at the end of settings.rb.
    # Proxy class for managing settings with a target object.
    # This class allows for delegation of method calls to a target object,
    # while providing additional functionality such as logging and handling
    # detached states.
    # @example Creating a SettingsProxy instance
    #   proxy = SettingsProxy.new(Settings, scope, path, target)
    class SettingsProxy
      LOG_PREFIX = "[SettingsProxy]".freeze

      # Minimal change: add detached flag (default false)
      # Initializes a new SettingsProxy instance.
      # @param settings_module [Module] The Settings module itself.
      # @param scope [Object] The scope in which the settings are defined.
      # @param path [Array] The path to the settings.
      # @param target [Object] The target object to delegate to.
      # @param detached [Boolean] Whether the proxy is detached (default: false).
      # @return [SettingsProxy]
      # @example
      #   proxy = SettingsProxy.new(Settings, scope, path, target, detached: true)
      def initialize(settings_module, scope, path, target, detached: false)
        @settings_module = settings_module # This should be the Settings module itself
        @scope  = scope
        @path   = path.dup
        @target = target
        @detached = detached
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "INIT scope: #{@scope.inspect}, path: #{@path.inspect}, target_class: #{@target.class}, target_object_id: #{@target.object_id}, detached: #{@detached}" })
      end

      attr_reader :target, :path, :scope

      # Minimal change: expose detached? status
      # Checks if the proxy is in a detached state.
      # @return [Boolean] Returns true if the proxy is detached, false otherwise.
      # @example
      #   if proxy.detached?
      #     puts "Proxy is detached"
      #   end
      def detached?
        !!@detached
      end

      # Checks if the target is nil.
      # @return [Boolean] Returns true if the target is nil, false otherwise.
      def nil?
        @target.nil?
      end

      # Performs a binary operation with the target and another value.
      # @param operator [Symbol] The operator to apply (e.g., :+, :-).
      # @param other [Object] The other operand for the operation.
      # @return [Object] The result of the operation.
      def binary_op(operator, other)
        other_value = other.is_a?(SettingsProxy) ? other.target : other
        @target.send(operator, other_value)
      end

      [:==, :!=, :eql?, :equal?, :<=>, :<, :<=, :>, :>=, :|, :&].each do |op|
        define_method(op) do |other|
          binary_op(op, other)
        end
      end

      # Returns the hash of the target object.
      # @return [Integer] The hash value of the target.
      def hash
        @target.hash
      end

      # Helper method for delegating conversion methods with appropriate return types
      # Helper method for delegating conversion methods with appropriate return types.
      # @param method [Symbol] The conversion method to delegate.
      # @param options [Hash] Options for delegation, including :strict and :default.
      # @return [Object] The result of the delegated method.
      # @raise [NoMethodError] If strict is true and the method is not supported.
      private def delegate_conversion(method, options = {})
        if @target.respond_to?(method)
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "#{method}: delegating" })
          @target.send(method)
        else
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "#{method}: not supported" })

          if options[:strict]
            # For strict methods, raise NoMethodError
            raise NoMethodError.new("undefined method `#{method}' for #{@target.inspect}:#{@target.class}")
          else
            # For permissive methods, return the default value
            options[:default]
          end
        end
      end

      # Internal: rebind this proxy to the live container and clear detached state.
      # This centralizes target swaps so invariants/logging stay consistent.
      # @param new_target [Hash, Array] the live container resolved from root+path
      # @return [self]
      # Rebinds this proxy to a new live target and clears the detached state.
      # This centralizes target swaps so invariants/logging stay consistent.
      # @param new_target [Hash, Array] The live container resolved from root+path.
      # @return [self] Returns the current instance.
      private def rebind_to_live!(new_target)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> {
          "REBIND to live: old_target_oid=#{@target&.object_id}, new_target_oid=#{new_target&.object_id}, scope=#{@scope.inspect}, path=#{@path.inspect}"
        })
        @target = new_target
        @detached = false if instance_variable_defined?(:@detached)
        self
      end

      # String conversions
      # Converts the target to a string.
      # @return [String] The string representation of the target.
      def to_s
        delegate_conversion(:to_s, default: '')
      end

      # Converts the target to a string, strict version.
      # @return [String] The string representation of the target.
      # @raise [NoMethodError] If the target does not respond to to_str.
      def to_str
        delegate_conversion(:to_str, strict: true)
      end

      def to_sym
        delegate_conversion(:to_sym, strict: true)
      end

      # Numeric conversions
      # Converts the target to an integer.
      # @return [Integer] The integer representation of the target.
      # @note Returns 0 if the target does not respond to to_i.
      def to_i
        delegate_conversion(:to_i, default: 0)
      end

      def to_int
        delegate_conversion(:to_int, strict: true)
      end

      def to_f
        delegate_conversion(:to_f, default: 0.0)
      end

      def to_r
        delegate_conversion(:to_r, strict: true)
      end

      def to_c
        delegate_conversion(:to_c, default: Complex(0, 0))
      end

      # Collection conversions
      def to_a
        delegate_conversion(:to_a, default: [])
      end

      def to_ary
        delegate_conversion(:to_ary, strict: true)
      end

      def to_h
        delegate_conversion(:to_h, default: {})
      end

      def to_hash
        delegate_conversion(:to_hash, strict: true)
      end

      # added 20250620 for JSON.pretty_generate
      # Converts the target to JSON format.
      # @param args [Array] Additional arguments for JSON conversion.
      # @return [String] The JSON representation of the target.
      # @raise [NoMethodError] If the target does not respond to to_json.
      # @example
      #   json_output = proxy.to_json
      def to_json(*args)
        if @target.respond_to?(:to_json)
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "to_json: delegating with args" })
          @target.to_json(*args)
        else
          raise NoMethodError, "undefined method :to_json for #{@target.inspect}:#{@target.class}"
        end
      end

      # Other common conversions
      def to_proc
        delegate_conversion(:to_proc, strict: true)
      end

      def to_io
        delegate_conversion(:to_io, strict: true)
      end

      def to_path
        delegate_conversion(:to_path, strict: true)
      end

      # Special case for to_enum
      def to_enum(*args, &block)
        if @target.respond_to?(:to_enum)
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "to_enum: delegating" })
          @target.to_enum(*args, &block)
        else
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "to_enum: using default enum_for" })
          self.enum_for(*args, &block)
        end
      end

      # Updated inspect method to show the target's inspect string
      # Returns a string representation of the proxy's target.
      # @return [String] The inspect string of the target.
      def inspect
        @target.inspect
      end

      # New method to show the proxy's internal details
      # Returns a string with the proxy's internal details.
      # @return [String] A detailed string representation of the proxy.
      def proxy_details
        "<SettingsProxy scope=#{@scope.inspect} path=#{@path.inspect} target_class=#{@target.class} target_object_id=#{@target.object_id} detached=#{@detached}>"
      end

      def pretty_print(pp)
        pp.pp(@target)
      end

      def is_a?(klass)
        @target.is_a?(klass)
      end

      def kind_of?(klass)
        @target.kind_of?(klass)
      end

      def instance_of?(klass)
        @target.instance_of?(klass)
      end

      def respond_to?(method, include_private = false)
        super || @target.respond_to?(method, include_private)
      end

      # Minimal change: items yielded from #each are "views" over the container.
      # Mark them detached so mutations during a derived iteration won't clobber root.
      # Iterates over the target, yielding each item.
      # Items yielded from #each are "views" over the container.
      # @yield [Object] Each item in the target.
      # @return [self] Returns the current instance.
      def each(&_block)
        return enum_for(:each) unless block_given?
        if @target.respond_to?(:each)
          @target.each do |item|
            if @settings_module.container?(item)
              yield SettingsProxy.new(@settings_module, @scope, [], item, detached: true)
            else
              yield item
            end
          end
        end
        self
      end

      NON_DESTRUCTIVE_METHODS = [
        :+, :-, :&, :|, :*,
        :all?, :any?, :assoc, :at, :bsearch, :bsearch_index, :chunk, :chunk_while,
        :collect, :collect_concat, :compact, :compare_by_identity?, :count, :cycle,
        :default, :default_proc, :detect, :dig, :drop, :drop_while,
        :each_cons, :each_entry, :each_slice, :each_with_index, :each_with_object, :empty?,
        :entries, :except, :fetch, :fetch_values, :filter, :find, :find_all, :find_index,
        :first, :flat_map, :flatten, :frozen?, :grep, :grep_v, :group_by, :has_value?,
        :include?, :inject, :invert, :join, :key, :keys, :last, :lazy, :length,
        :map, :max, :max_by, :member?, :merge, :min, :min_by, :minmax, :minmax_by,
        :none?, :one?, :pack, :partition, :permutation, :product, :rassoc, :reduce,
        :reject, :reverse, :rotate, :sample, :select, :shuffle, :size, :slice,
        :slice_after, :slice_before, :slice_when, :sort, :sort_by, :sum,
        :take, :take_while, :to_a, :to_h, :to_proc, :transform_keys, :transform_values,
        :uniq, :values, :values_at, :zip
      ].freeze

      # Subset of non-destructive methods that return container "views"
      NON_DESTRUCTIVE_CONTAINER_VIEWS = [
        :map, :collect, :select, :filter, :reject, :find_all, :grep, :grep_v,
        :sort, :sort_by, :uniq, :compact, :flatten, :slice, :take, :drop, :values
      ].freeze

      # Retrieves a value from the target using the specified key.
      # @param key [Object] The key to retrieve the value for.
      # @return [Object] The value associated with the key, or a new SettingsProxy if the value is a container.
      def [](key)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "GET scope: #{@scope.inspect}, path: #{@path.inspect}, key: #{key.inspect}, target_object_id: #{@target.object_id}" })
        value = @target[key]
        if @settings_module.container?(value)
          new_path = @path.dup
          new_path << key
          SettingsProxy.new(@settings_module, @scope, new_path, value)
        else
          value
        end
      end

      # Sets a value in the target using the specified key.
      # @param key [Object] The key to set the value for.
      # @param value [Object] The value to set.
      # @return [Object] The value that was set.
      def []=(key, value)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET scope: #{@scope.inspect}, path: #{@path.inspect}, key: #{key.inspect}, value: #{value.inspect}, target_object_id: #{@target.object_id}" })
        actual_value = value.is_a?(SettingsProxy) ? @settings_module.unwrap_proxies(value) : value # Corrected to use @settings_module
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET   target_before_set: #{@target.inspect}" })
        @target[key] = actual_value
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET   target_after_set: #{@target.inspect}" })
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET   calling save_proxy_changes on settings module" })
        @settings_module.save_proxy_changes(self)
        # rubocop:disable Lint/Void
        # This is Ruby expected behavior to return the value.
        value
        # rubocop:enable Lint/Void
      end

      # Handles calls to methods that are not explicitly defined.
      # @param method [Symbol] The method name being called.
      # @param args [Array] The arguments for the method.
      # @param block [Proc] An optional block for the method.
      # @return [Object] The result of the method call, or raises NoMethodError if not found.
      def method_missing(method, *args, &block)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL scope: #{@scope.inspect}, path: #{@path.inspect}, method: #{method}, args: #{args.inspect}, target_object_id: #{@target.object_id}" })
        if @target.respond_to?(method)
          if NON_DESTRUCTIVE_METHODS.include?(method)
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   non-destructive method: #{method}" })
            target_dup = @target.dup
            unwrapped_args = args.map { |arg| arg.is_a?(SettingsProxy) ? @settings_module.unwrap_proxies(arg) : arg } # Corrected
            result = target_dup.send(method, *unwrapped_args, &block)
            # Minimal change: pass method name so we can tag views as detached and keep path
            return handle_non_destructive_result(method, result)
          else
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   destructive method: #{method}" })

            # NEW (5.12.7+): auto-reattach derived views before mutating
            # ensure destructive methods (.push) do not target a proxy non-destructive method (.sort)
            if detached?
              unless @settings_module._reattach_live!(self)
                @settings_module._log(Settings::LOG_LEVEL_ERROR, LOG_PREFIX, -> { "CALL   reattach failed; aborting destructive op #{method} on detached view" })
                return self
              end
            end

            unwrapped_args = args.map { |arg| arg.is_a?(SettingsProxy) ? @settings_module.unwrap_proxies(arg) : arg } # Corrected
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   target_before_op: #{@target.inspect}" })
            result = @target.send(method, *unwrapped_args, &block)
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   target_after_op: #{@target.inspect}" })
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   calling save_proxy_changes on settings module" })
            @settings_module.save_proxy_changes(self)
            return handle_method_result(result)
          end
        else
          super
        end
      end

      # Minimal change: keep path (not []), and tag view proxies as detached.
      def handle_non_destructive_result(method, result)
        @settings_module.reset_path_and_return(
          if @settings_module.container?(result)
            is_view = NON_DESTRUCTIVE_CONTAINER_VIEWS.include?(method)
            SettingsProxy.new(@settings_module, @scope, @path.dup, result, detached: is_view)
          else
            result
          end
        )
      end

      def handle_method_result(result)
        if result.equal?(@target)
          self # Return self if the method modified the target in-place and returned it
        elsif @settings_module.container?(result)
          # If a new container is returned (e.g. some destructive methods might return a new object)
          # Wrap it in a new proxy, maintaining the current path and scope.
          SettingsProxy.new(@settings_module, @scope, @path, result)
        else
          result
        end
      end

      # Checks if the target responds to a method, including private methods.
      # @param method [Symbol] The method name to check.
      # @param include_private [Boolean] Whether to include private methods in the check.
      # @return [Boolean] Returns true if the method is found, false otherwise.
      def respond_to_missing?(method, include_private = false)
        @target.respond_to?(method, include_private) || super
      end
    end
  end
end
