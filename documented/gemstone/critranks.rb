# frozen_string_literal: true

#
# module CritRanks used to resolve critical hits into their mechanical results
# queries against crit_tables files in lib/crit_tables/
# 20240625
#

#
# See generic_critical_table.rb for the general template used
#
module Lich
  module Gemstone
    # Module CritRanks used to resolve critical hits into their mechanical results
    #
    # This module queries against crit_tables files in lib/crit_tables/
    #
    # @example Usage
    #   Lich::Gemstone::CritRanks.init
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks           = []

      # Initializes the critical table by loading critical_table.rb files.
      # @return [void]
      # @note This method will only load files if the critical table is empty.
      # @example Initializing the critical table
      #   Lich::Gemstone::CritRanks.init
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      # Returns the current critical table.
      # @return [Hash] The critical table containing critical hit data.
      # @example Accessing the critical table
      #   critical_data = Lich::Gemstone::CritRanks.table
      def self.table
        @critical_table
      end

      # Reloads the critical table by clearing it and reinitializing.
      # @return [void]
      # @example Reloading the critical table
      #   Lich::Gemstone::CritRanks.reload!
      def self.reload!
        @critical_table = {}
        init
      end

      # Returns an array of table names from the critical table.
      # @return [Array<String>] An array of table names.
      # @example Getting table names
      #   table_names = Lich::Gemstone::CritRanks.tables
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      # Returns an array of types from the critical table.
      # @return [Array] An array of types.
      # @example Getting types
      #   types = Lich::Gemstone::CritRanks.types
      def self.types
        @types
      end

      # Returns an array of locations from the critical table.
      # @return [Array] An array of locations.
      # @example Getting locations
      #   locations = Lich::Gemstone::CritRanks.locations
      def self.locations
        @locations
      end

      # Returns an array of ranks from the critical table.
      # @return [Array] An array of ranks.
      # @example Getting ranks
      #   ranks = Lich::Gemstone::CritRanks.ranks
      def self.ranks
        @ranks
      end

      # Cleans the provided key by converting it to a standard format.
      # @param key [String, Symbol, Integer] The key to clean.
      # @return [String, Integer] The cleaned key.
      # @example Cleaning a key
      #   cleaned_key = Lich::Gemstone::CritRanks.clean_key(:SomeKey)
      def self.clean_key(key)
        return key.to_i if key.is_a?(Integer) || key =~ (/^\d+$/)
        return key.downcase if key.is_a?(Symbol)

        key.strip.downcase.gsub(/[ -]/, '_')
      end

      # Validates the provided key against a list of valid keys.
      # @param key [String, Symbol, Integer] The key to validate.
      # @param valid [Array] An array of valid keys.
      # @return [String] The cleaned key if valid.
      # @raise [RuntimeError] If the key is invalid.
      # @example Validating a key
      #   valid_key = Lich::Gemstone::CritRanks.validate(:SomeKey, Lich::Gemstone::CritRanks.types)
      def self.validate(key, valid)
        clean = clean_key(key)
        raise "Invalid key '#{key}', expecting one of #{valid.join(',')}" unless valid.include?(clean)

        clean
      end

      # Creates indices for types, locations, and ranks from the critical table.
      # @return [void]
      # @note This method is called internally to set up the indices.
      # @example Creating indices
      #   Lich::Gemstone::CritRanks.create_indices
      def self.create_indices
        @index_rx ||= {}
        @critical_table.each do |type, typedata|
          @types.append(type)
          typedata.each do |loc, locdata|
            @locations.append(loc) unless @locations.include?(loc)
            locdata.each do |rank, record|
              @ranks.append(rank) unless @ranks.include?(rank)
              @index_rx[record[:regex]] = record
            end
          end
        end
      end

      # Parses a line against the regex patterns in the critical table.
      # @param line [String] The line to parse.
      # @return [Hash] A hash of matched regex patterns and their data.
      # @example Parsing a line
      #   matches = Lich::Gemstone::CritRanks.parse("Some input line")
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      # Fetches data from the critical table based on type, location, and rank.
      # @param type [String] The type of critical hit.
      # @param location [String] The location of the critical hit.
      # @param rank [String] The rank of the critical hit.
      # @return [Hash, nil] The data for the specified type, location, and rank, or nil if not found.
      # @raise [StandardError] If an error occurs during fetching.
      # @example Fetching data
      #   data = Lich::Gemstone::CritRanks.fetch(:type, :location, :rank)
      def self.fetch(type, location, rank)
        table.dig(
          validate(type, types),
          validate(location, locations),
          validate(rank, ranks)
        )
      rescue StandardError => e
        Lich::Messaging.msg('error', "Error! #{e}")
      end
      # startup
      init
    end
  end
end
