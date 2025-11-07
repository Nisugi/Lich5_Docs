# frozen_string_literal: true

# Recreating / bridging the design for CharSettings to lift in scripts into lib
# as with infomon rewrite
# Also tuning slightly, to improve / reduce db calls made by CharSettings
# 20240801 - updated to include vars (uservars) settings to support renaming characters

require 'English'

module Lich
  # Provides common database storage functionality for Lich
  # This module contains methods to read and save data related to character settings.
  # @example Using the DB_Store module
  #   Lich::Common::DB_Store.read("game:name", "vars")
  module Common
    module DB_Store
      # Reads data from the database based on the provided scope and script name.
      # @param scope [String] The scope for the data, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] The name of the script to read data for
      # @return [Hash] The data retrieved from the database
      # @raise [StandardError] If there is an error during the database operation
      # @example
      #   data = Lich::Common::DB_Store.read("game:name", "vars")
      def self.read(scope = "#{XMLData.game}:#{XMLData.name}", script)
        case script
        when 'vars', 'uservars'
          get_vars(scope)
        else
          get_data(scope, script)
        end
      end

      # Saves data to the database based on the provided scope, script name, and value.
      # @param scope [String] The scope for the data, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] The name of the script to save data for
      # @param val [Object] The value to be saved in the database
      # @return [String] A message indicating success or error
      # @raise [StandardError] If there is an error during the database operation
      # @example
      #   result = Lich::Common::DB_Store.save("game:name", "vars", { key: "value" })
      def self.save(scope = "#{XMLData.game}:#{XMLData.name}", script, val)
        case script
        when 'vars', 'uservars'
          store_vars(scope, val)
        else
          store_data(scope, script, val)
        end
      end

      # Retrieves data from the database for a specific script and scope.
      # @param scope [String] The scope for the data, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] The name of the script to retrieve data for
      # @return [Hash] The data retrieved from the database, or an empty hash if not found
      # @raise [StandardError] If there is an error during the database operation
      # @example
      #   data = Lich::Common::DB_Store.get_data("game:name", "script_name")
      def self.get_data(scope = "#{XMLData.game}:#{XMLData.name}", script)
        hash = Lich.db.get_first_value('SELECT hash FROM script_auto_settings WHERE script=? AND scope=?;', [script.encode('UTF-8'), scope.encode('UTF-8')])
        return {} unless hash
        Marshal.load(hash)
      end

      # Retrieves user variables from the database for a specific scope.
      # @param scope [String] The scope for the user variables, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @return [Hash] The user variables retrieved from the database, or an empty hash if not found
      # @raise [StandardError] If there is an error during the database operation
      # @example
      #   user_vars = Lich::Common::DB_Store.get_vars("game:name")
      def self.get_vars(scope = "#{XMLData.game}:#{XMLData.name}")
        hash = Lich.db.get_first_value('SELECT hash FROM uservars WHERE scope=?;', scope.encode('UTF-8'))
        return {} unless hash
        Marshal.load(hash)
      end

      # Stores data in the database for a specific script and scope.
      # @param scope [String] The scope for the data, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] The name of the script to save data for
      # @param val [Object] The value to be stored in the database
      # @return [String] A message indicating success or error
      # @raise [StandardError] If there is an error during the database operation
      # @note This method is synchronized to prevent concurrent access issues.
      # @example
      #   result = Lich::Common::DB_Store.store_data("game:name", "script_name", { key: "value" })
      def self.store_data(scope = "#{XMLData.game}:#{XMLData.name}", script, val)
        blob = SQLite3::Blob.new(Marshal.dump(val))
        return 'Error: No data to store.' unless blob

        Lich.db_mutex.synchronize do
          begin
            Lich.db.execute('INSERT OR REPLACE INTO script_auto_settings(script,scope,hash) VALUES(?,?,?);', [script.encode('UTF-8'), scope.encode('UTF-8'), blob])
          rescue SQLite3::BusyException
            sleep 0.05
            retry
          rescue StandardError
            respond "--- Lich: error: #{$ERROR_INFO}"
            respond $ERROR_INFO.backtrace[0..1]
          end
        end
      end

      # Stores user variables in the database for a specific scope.
      # @param scope [String] The scope for the user variables, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param val [Object] The user variables to be stored in the database
      # @return [String] A message indicating success or error
      # @raise [StandardError] If there is an error during the database operation
      # @note This method is synchronized to prevent concurrent access issues.
      # @example
      #   result = Lich::Common::DB_Store.store_vars("game:name", { user_key: "user_value" })
      def self.store_vars(scope = "#{XMLData.game}:#{XMLData.name}", val)
        blob = SQLite3::Blob.new(Marshal.dump(val))
        return 'Error: No data to store.' unless blob

        Lich.db_mutex.synchronize do
          begin
            Lich.db.execute('INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);', [scope.encode('UTF-8'), blob])
          rescue SQLite3::BusyException
            sleep 0.05
            retry
          rescue StandardError
            respond "--- Lich: error: #{$ERROR_INFO}"
            respond $ERROR_INFO.backtrace[0..1]
          end
        end
      end
    end
  end
end
