module Lich
  module DragonRealms
    # Provides functionality related to spells in the DragonRealms game.
    # This module manages known spells, feats, and spellbook formats.
    # @example Accessing known spells
    #   known_spells = Lich::DragonRealms::DRSpells.known_spells
    module DRSpells
      # A hash storing known spells.
      @@known_spells = {}
      # A hash storing known feats.
      @@known_feats = {}
      # The format of the spellbook, can be 'column-formatted' or 'non-column'.
      @@spellbook_format = nil # 'column-formatted' or 'non-column'

      # Indicates if the module is currently grabbing known spells.
      @@grabbing_known_spells = false
      # Indicates if the module is currently grabbing known barbarian abilities.
      @@grabbing_known_barbarian_abilities = false
      # Indicates if the module is currently grabbing known khri.
      @@grabbing_known_khri = false

      # Retrieves the currently active spells.
      # @return [Hash] A hash of active spells.
      def self.active_spells
        XMLData.dr_active_spells
      end

      # Returns the known spells.
      # @return [Hash] A hash of known spells.
      def self.known_spells
        @@known_spells
      end

      # Returns the known feats.
      # @return [Hash] A hash of known feats.
      def self.known_feats
        @@known_feats
      end

      # Retrieves the slivers of currently active spells.
      # @return [Array] An array of spell slivers.
      def self.slivers
        XMLData.dr_active_spells_slivers
      end

      # Retrieves the stellar percentage of active spells.
      # @return [Float] The stellar percentage.
      def self.stellar_percentage
        XMLData.dr_active_spells_stellar_percentage
      end

      # Checks if the module is currently grabbing known spells.
      # @return [Boolean] True if grabbing known spells, false otherwise.
      def self.grabbing_known_spells
        @@grabbing_known_spells
      end

      # Sets the state of grabbing known spells.
      # @param val [Boolean] The state to set for grabbing known spells.
      # @return [Boolean] The value that was set.
      def self.grabbing_known_spells=(val)
        @@grabbing_known_spells = val
      end

      # Checks if the module is currently grabbing known barbarian abilities.
      # @return [Boolean] True if grabbing known barbarian abilities, false otherwise.
      def self.check_known_barbarian_abilities
        @@grabbing_known_barbarian_abilities
      end

      # Sets the state of grabbing known barbarian abilities.
      # @param val [Boolean] The state to set for grabbing known barbarian abilities.
      # @return [Boolean] The value that was set.
      def self.check_known_barbarian_abilities=(val)
        @@grabbing_known_barbarian_abilities = val
      end

      # Checks if the module is currently grabbing known khri.
      # @return [Boolean] True if grabbing known khri, false otherwise.
      def self.grabbing_known_khri
        @@grabbing_known_khri
      end

      # Sets the state of grabbing known khri.
      # @param val [Boolean] The state to set for grabbing known khri.
      # @return [Boolean] The value that was set.
      def self.grabbing_known_khri=(val)
        @@grabbing_known_khri = val
      end

      # Retrieves the current spellbook format.
      # @return [String, nil] The spellbook format, or nil if not set.
      def self.spellbook_format
        @@spellbook_format
      end

      # Sets the spellbook format.
      # @param val [String] The format to set for the spellbook.
      # @return [String] The value that was set.
      def self.spellbook_format=(val)
        @@spellbook_format = val
      end
    end
  end
end
