# Carve out module Vars (should this be in settings path?)
# 2024-06-13

# Provides common functionality for the Lich project
# This module contains shared variables and methods for managing them.
# @example Including the Lich module
#   include Lich
module Lich
  module Common
    # Manages a set of variables for the Lich project
    # This module provides methods to load, save, and access variables.
    # @example Accessing a variable
    #   value = Vars["key"]
    module Vars
      # A hash that stores the variables
      # This hash is used to store key-value pairs of variables.
      @@vars   = Hash.new
      # A variable to store the MD5 hash of the variables
      # This is used to check if the variables have changed.
      md5      = nil
      # A flag indicating whether the variables have been loaded
      # This prevents reloading the variables unnecessarily.
      @@loaded = false
      @@load = proc {
        Lich.db_mutex.synchronize {
          unless @@loaded
            begin
              h = Lich.db.get_first_value('SELECT hash FROM uservars WHERE scope=?;', ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8')])
            rescue SQLite3::BusyException
              sleep 0.1
              retry
            end
            if h
              begin
                hash = Marshal.load(h)
                hash.each { |k, v| @@vars[k] = v }
                md5 = Digest::MD5.hexdigest(hash.to_s)
              rescue
                respond "--- Lich: error: #{$!}"
                respond $!.backtrace[0..2]
              end
            end
            @@loaded = true
          end
        }
        nil
      }
      @@save = proc {
        Lich.db_mutex.synchronize {
          if @@loaded
            if Digest::MD5.hexdigest(@@vars.to_s) != md5
              md5 = Digest::MD5.hexdigest(@@vars.to_s)
              blob = SQLite3::Blob.new(Marshal.dump(@@vars))
              begin
                Lich.db.execute('INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);', ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8'), blob])
              rescue SQLite3::BusyException
                sleep 0.1
                retry
              end
            end
          end
        }
        nil
      }
      Thread.new {
        loop {
          sleep 300
          begin
            @@save.call
          rescue
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
          end
        }
      }
      # Retrieves the value of a variable by name
      # @param name [String] The name of the variable to retrieve
      # @return [Object] The value of the variable, or nil if not found
      # @example Accessing a variable
      #   value = Vars["key"]
      def Vars.[](name)
        @@load.call unless @@loaded
        @@vars[name]
      end

      # Sets the value of a variable by name
      # @param name [String] The name of the variable to set
      # @param val [Object] The value to assign to the variable
      # @return [Object] The value that was set
      # @example Setting a variable
      #   Vars["key"] = "value"
      def Vars.[]=(name, val)
        @@load.call unless @@loaded
        if val.nil?
          @@vars.delete(name)
        else
          @@vars[name] = val
        end
      end

      # Returns a duplicate of the current variables
      # @return [Hash] A hash containing all current variables
      # @example Listing all variables
      #   all_vars = Vars.list
      def Vars.list
        @@load.call unless @@loaded
        @@vars.dup
      end

      # Saves the current variables to the database
      # @return [nil] Always returns nil
      # @example Saving variables
      #   Vars.save
      def Vars.save
        @@save.call
      end

      # Handles dynamic method calls for variable access
      # @param arg1 [Symbol] The method name called
      # @param arg2 [Object] The value to set if the method is a setter
      # @return [Object] The value of the variable or nil
      # @example Using dynamic methods
      #   Vars.some_variable = "value"
      #   Vars.some_variable
      def Vars.method_missing(arg1, arg2 = '')
        @@load.call unless @@loaded
        if arg1[-1, 1] == '='
          if arg2.nil?
            @@vars.delete(arg1.to_s.chop)
          else
            @@vars[arg1.to_s.chop] = arg2
          end
        else
          @@vars[arg1.to_s]
        end
      end
    end
  end
end
