module Lich
  module Common
    # Database adapter to separate database concerns
    # Database adapter to separate database concerns
    #
    # This class handles the interaction with the database, including
    # setting up the database table and saving/loading settings.
    # @example Creating a new database adapter
    #   adapter = Lich::Common::DatabaseAdapter.new("/path/to/data", "settings_table")
    class DatabaseAdapter
      # Initializes a new DatabaseAdapter instance.
      #
      # @param data_dir [String] The directory where the database file is located.
      # @param table_name [String] The name of the table to use in the database.
      # @return [DatabaseAdapter] The instance of the DatabaseAdapter.
      def initialize(data_dir, table_name)
        @file = File.join(data_dir, "lich.db3")
        @db = Sequel.sqlite(@file)
        @table_name = table_name
        setup!
      end

      # Sets up the database table if it does not exist.
      #
      # @return [void]
      def setup!
        @db.create_table?(@table_name) do
          text :script
          text :scope
          blob :hash
        end
        @table = @db[@table_name]
      end

      # Returns the database table object.
      #
      # @return [Sequel::Dataset] The dataset representing the table.
      def table
        @table
      end

      # Retrieves settings for a given script and scope.
      #
      # @param script_name [String] The name of the script to retrieve settings for.
      # @param scope [String] The scope of the settings (default is ":").
      # @return [Hash] The settings as a hash, or an empty hash if not found.
      def get_settings(script_name, scope = ":")
        entry = @table.first(script: script_name, scope: scope)
        entry.nil? ? {} : Marshal.load(entry[:hash])
      end

      # Saves settings for a given script and scope.
      #
      # @param script_name [String] The name of the script to save settings for.
      # @param settings [Hash] The settings to save.
      # @param scope [String] The scope of the settings (default is ":").
      # @return [Boolean] True if settings were saved successfully, false otherwise.
      # @raise [ArgumentError] If settings is not a Hash.
      # @raise [Sequel::DatabaseError] If there is a database error while saving.
      # @example Saving settings
      #   adapter.save_settings("my_script", {"key" => "value"})
      def save_settings(script_name, settings, scope = ":")
        unless settings.is_a?(Hash)
          Lich::Messaging.msg("error", "--- Error: Report this - settings must be a Hash, got #{settings.class} ---")
          Lich.log("--- Error: settings must be a Hash, got #{settings.class} from call initiated by #{script_name} ---")
          Lich.log(settings.inspect)
          return false
        end

        begin
          blob = Sequel::SQL::Blob.new(Marshal.dump(settings))
        rescue => e
          Lich::Messaging.msg("error", "--- Error: failed to serialize settings ---")
          Lich.log("--- Error: failed to serialize settings ---")
          Lich.log("#{e.message}\n#{e.backtrace.join("\n")}")
          return false
        end

        begin
          @table
            .insert_conflict(target: [:script, :scope], update: { hash: blob })
            .insert(script: script_name, scope: scope, hash: blob)
          return true
        rescue Sequel::DatabaseError => db_err
          Lich::Messaging.msg("error", "--- Database error while saving settings ---")
          Lich.log("--- Database error while saving settings ---")
          Lich.log("#{db_err.message}\n#{db_err.backtrace.join("\n")}")
        rescue => e
          Lich::Messaging.msg("error", "--- Unexpected error while saving settings ---")
          Lich.log("--- Unexpected error while saving settings ---")
          Lich.log("#{e.message}\n#{e.backtrace.join("\n")}")
        end

        false
      end
    end
  end
end
