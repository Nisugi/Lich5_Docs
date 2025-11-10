module Lich
  module Common
    module Vars
      # @!visibility private
      module LoadState
        UNLOADED = :unloaded
        LOADING  = :loading
        LOADED   = :loaded
      end

      @@vars       = Hash.new
      @@md5        = nil
      @@load_state = LoadState::UNLOADED

      def self.normalize_key(key)
        key.to_s
      end

      # Proc that loads variables from database on first access
      @@load = proc {
        Lich.db_mutex.synchronize {
          if @@load_state == LoadState::UNLOADED
            @@load_state = LoadState::LOADING
            begin
              h = Lich.db.get_first_value(
                'SELECT hash FROM uservars WHERE scope=?;',
                ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8')]
              )
            rescue SQLite3::BusyException
              sleep 0.1
              retry
            end

            if h
              begin
                hash = Marshal.load(h)
                # Normalize all keys to strings during load
                hash.each { |k, v| @@vars[normalize_key(k)] = v }
                @@md5 = Digest::MD5.hexdigest(hash.to_s)
              rescue StandardError => e
                respond "--- Lich: error: #{e}"
                respond e.backtrace[0..2]
              end
            end
            @@load_state = LoadState::LOADED
          end
        }
        nil
      }

      # Proc that saves variables to database if modified
      @@save = proc {
        Lich.db_mutex.synchronize {
          if @@load_state == LoadState::LOADED
            current_md5 = Digest::MD5.hexdigest(@@vars.to_s)
            if current_md5 != @@md5
              @@md5 = current_md5
              blob = SQLite3::Blob.new(Marshal.dump(@@vars))
              begin
                Lich.db.execute(
                  'INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);',
                  ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8'), blob]
                )
              rescue SQLite3::BusyException
                sleep 0.1
                retry
              end
            end
          end
        }
        nil
      }

      # Background thread that auto-saves variables every 5 minutes
      Thread.new {
        loop {
          sleep 300
          begin
            @@save.call
          rescue StandardError => e
            Lich.log "error: #{e}\n\t#{e.backtrace.join("\n\t")}"
            respond "--- Lich: error: #{e}\n\t#{e.backtrace[0..1].join("\n\t")}"
          end
        }
      }

      # Retrieves the value associated with the given variable name.
      # @param name [String] The name of the variable to retrieve.
      # @return [Object] The value associated with the variable name.
      # @example
      #   value = Vars["my_variable"]
      def Vars.[](name)
        @@load.call unless @@load_state == LoadState::LOADED
        @@vars[normalize_key(name)]
      end

      # Sets the value for the given variable name.
      # @param name [String] The name of the variable to set.
      # @param val [Object] The value to assign to the variable.
      # @return [Object] The value that was set.
      # @example
      #   Vars["my_variable"] = "new_value"
      def Vars.[]=(name, val)
        @@load.call unless @@load_state == LoadState::LOADED
        key = normalize_key(name)
        if val.nil?
          @@vars.delete(key)
        else
          @@vars[key] = val
        end
      end

      # Returns a duplicate of the current variables hash.
      # @return [Hash] A duplicate of the variables hash.
      # @example
      #   all_vars = Vars.list
      def Vars.list
        @@load.call unless @@load_state == LoadState::LOADED
        @@vars.dup
      end

      # Saves the current variables to the database if modified.
      # @return [nil]
      # @example
      #   Vars.save
      def Vars.save
        @@save.call
      end

      def Vars.method_missing(method_name, *args)
        @@load.call unless @@load_state == LoadState::LOADED

        # Handle []= called through method_missing
        if method_name == :[]= && args.length == 2
          key = normalize_key(args[0])
          if args[1].nil?
            @@vars.delete(key)
          else
            @@vars[key] = args[1]
          end
        # Handle [] called through method_missing
        elsif method_name == :[] && args.length == 1
          @@vars[normalize_key(args[0])]
        # Handle setter methods (e.g., foo=)
        elsif method_name.to_s.end_with?('=')
          key = normalize_key(method_name.to_s.chop)
          if args[0].nil?
            @@vars.delete(key)
          else
            @@vars[key] = args[0]
          end
        # Handle getter methods
        else
          @@vars[normalize_key(method_name.to_s)]
        end
      end

      # Checks if the object responds to the given method name.
      # @param method_name [Symbol] The method name to check.
      # @param _include_private [Boolean] Whether to include private methods in the check.
      # @return [Boolean] True if the method exists, false otherwise.
      # @example
      #   Vars.respond_to_missing?(:my_method)
      def Vars.respond_to_missing?(method_name, _include_private = false)
        method_str = method_name.to_s

        # Allow bracket operators
        return true if method_name == :[] || method_name == :[]=

        # Allow valid Ruby method names (with or without trailing =)
        # Valid: starts with letter or underscore, contains letters/digits/underscores
        # and optionally ends with = for setters
        method_str.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*=?\z/)
      end
    end
  end
end
