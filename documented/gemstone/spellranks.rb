# Carve out class SpellRanks
# 2024-06-13

module Lich
  module Gemstone
    # Represents the spell ranks in the Lich5 project.
    # This class handles loading, saving, and managing spell rank data.
    # @example Loading spell ranks
    #   SpellRanks.load
    class SpellRanks
      # A class variable that holds the list of spell ranks.
      @@list      ||= Array.new
      # A class variable that holds the timestamp for the last load.
      @@timestamp ||= 0
      # A class variable that indicates whether the spell ranks have been loaded.
      @@loaded    ||= false
      # The name of the spell rank.
      attr_reader :name
      # Accessors for various spell rank attributes.
      attr_accessor :minorspiritual, :majorspiritual, :cleric, :minorelemental, :majorelemental, :minormental, :ranger, :sorcerer, :wizard, :bard, :empath, :paladin, :arcanesymbols, :magicitemuse, :monk

      # Loads the spell ranks from a data file.
      # @return [void]
      # @raise [StandardError] if there is an error loading the data.
      # @example Loading spell ranks
      #   SpellRanks.load
      def SpellRanks.load
        if File.exist?(File.join(DATA_DIR, "#{XMLData.game}", "spell-ranks.dat"))
          begin
            File.open(File.join(DATA_DIR, "#{XMLData.game}", "spell-ranks.dat"), 'rb') { |f|
              @@timestamp, @@list = Marshal.load(f.read)
            }
            # minor mental circle added 2012-07-18; old data files will have @minormental as nil
            @@list.each { |rank_info| rank_info.minormental ||= 0 }
            # monk circle added 2013-01-15; old data files will have @minormental as nil
            @@list.each { |rank_info| rank_info.monk ||= 0 }
            @@loaded = true
          rescue
            respond "--- Lich: error: SpellRanks.load: #{$!}"
            Lich.log "error: SpellRanks.load: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            @@list      = Array.new
            @@timestamp = 0
            @@loaded = true
          end
        else
          @@loaded = true
        end
      end

      # Saves the current spell ranks to a data file.
      # @return [void]
      # @raise [StandardError] if there is an error saving the data.
      # @example Saving spell ranks
      #   SpellRanks.save
      def SpellRanks.save
        begin
          File.open(File.join(DATA_DIR, "#{XMLData.game}", "spell-ranks.dat"), 'wb') { |f|
            f.write(Marshal.dump([@@timestamp, @@list]))
          }
        rescue
          respond "--- Lich: error: SpellRanks.save: #{$!}"
          Lich.log "error: SpellRanks.save: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Retrieves the current timestamp for the spell ranks.
      # @return [Integer] the current timestamp.
      def SpellRanks.timestamp
        SpellRanks.load unless @@loaded
        @@timestamp
      end

      # Sets the timestamp for the spell ranks.
      # @param val [Integer] The new timestamp value.
      # @return [void]
      def SpellRanks.timestamp=(val)
        SpellRanks.load unless @@loaded
        @@timestamp = val
      end

      # Finds a spell rank by name.
      # @param name [String] The name of the spell rank to find.
      # @return [SpellRanks, nil] the found spell rank or nil if not found.
      # @example Finding a spell rank
      #   rank = SpellRanks["Fireball"]
      def SpellRanks.[](name)
        SpellRanks.load unless @@loaded
        @@list.find { |n| n.name == name }
      end

      # Retrieves the list of all spell ranks.
      # @return [Array<SpellRanks>] an array of all spell ranks.
      def SpellRanks.list
        SpellRanks.load unless @@loaded
        @@list
      end

      # Handles calls to undefined methods for the SpellRanks class.
      # @param arg [Symbol] The name of the method that was called.
      # @return [void]
      def SpellRanks.method_missing(arg = nil)
        echo "error: unknown method #{arg} for class SpellRanks"
        respond caller[0..1]
      end

      # Initializes a new SpellRanks object with a name.
      # @param name [String] The name of the spell rank.
      # @return [void]
      def initialize(name)
        SpellRanks.load unless @@loaded
        @name = name
        @minorspiritual, @majorspiritual, @cleric, @minorelemental, @majorelemental, @ranger, @sorcerer, @wizard, @bard, @empath, @paladin, @minormental, @arcanesymbols, @magicitemuse = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        @@list.push(self)
      end
    end
  end
end
