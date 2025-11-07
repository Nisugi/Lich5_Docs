# Module containing the Lich project functionality
# This module serves as a namespace for the DragonRealms module.
module Lich
  module DragonRealms
    # Module for managing DragonRealms character statistics
    # This module provides methods to access and modify character stats.
    # @example Accessing character race
    #   Lich::DragonRealms::DRStats.race
    module DRStats
      # The character's race
      # @return [String, nil] The race of the character or nil if not set.
      @@race = nil
      @@guild = nil
      # The character's gender
      # @return [String, nil] The gender of the character or nil if not set.
      @@gender = nil
      # The character's age
      # @return [Integer] The age of the character.
      @@age ||= 0
      # The character's circle
      # @return [Integer] The circle of the character.
      @@circle ||= 0
      # The character's strength
      # @return [Integer] The strength of the character.
      @@strength ||= 0
      # The character's stamina
      # @return [Integer] The stamina of the character.
      @@stamina ||= 0
      # The character's reflex
      # @return [Integer] The reflex of the character.
      @@reflex ||= 0
      # The character's agility
      # @return [Integer] The agility of the character.
      @@agility ||= 0
      # The character's intelligence
      # @return [Integer] The intelligence of the character.
      @@intelligence ||= 0
      # The character's wisdom
      # @return [Integer] The wisdom of the character.
      @@wisdom ||= 0
      # The character's discipline
      # @return [Integer] The discipline of the character.
      @@discipline ||= 0
      # The character's charisma
      # @return [Integer] The charisma of the character.
      @@charisma ||= 0
      # The character's favors
      # @return [Integer] The favors of the character.
      @@favors ||= 0
      # The character's TDPS (Total Damage Per Second)
      # @return [Integer] The TDPS of the character.
      @@tdps ||= 0
      # The character's encumbrance
      # @return [Integer, nil] The encumbrance of the character or nil if not set.
      @@encumbrance = nil
      # The character's balance
      # @return [Integer] The balance of the character.
      @@balance ||= 8
      # The character's luck
      # @return [Integer] The luck of the character.
      @@luck ||= 0

      # Retrieves the character's race
      # @return [String, nil] The race of the character or nil if not set.
      def self.race
        @@race
      end

      # Sets the character's race
      # @param val [String] The race to set for the character
      # @return [void]
      def self.race=(val)
        @@race = val
      end

      # Retrieves the character's guild
      # @return [String, nil] The guild of the character or nil if not set.
      def self.guild
        @@guild
      end

      # Sets the character's guild
      # @param val [String] The guild to set for the character
      # @return [void]
      def self.guild=(val)
        @@guild = val
      end

      # Retrieves the character's gender
      # @return [String, nil] The gender of the character or nil if not set.
      def self.gender
        @@gender
      end

      # Sets the character's gender
      # @param val [String] The gender to set for the character
      # @return [void]
      def self.gender=(val)
        @@gender = val
      end

      # Retrieves the character's age
      # @return [Integer] The age of the character.
      def self.age
        @@age
      end

      # Sets the character's age
      # @param val [Integer] The age to set for the character
      # @return [void]
      def self.age=(val)
        @@age = val
      end

      # Retrieves the character's circle
      # @return [Integer] The circle of the character.
      def self.circle
        @@circle
      end

      # Sets the character's circle
      # @param val [Integer] The circle to set for the character
      # @return [void]
      def self.circle=(val)
        @@circle = val
      end

      # Retrieves the character's strength
      # @return [Integer] The strength of the character.
      def self.strength
        @@strength
      end

      # Sets the character's strength
      # @param val [Integer] The strength to set for the character
      # @return [void]
      def self.strength=(val)
        @@strength = val
      end

      # Retrieves the character's stamina
      # @return [Integer] The stamina of the character.
      def self.stamina
        @@stamina
      end

      # Sets the character's stamina
      # @param val [Integer] The stamina to set for the character
      # @return [void]
      def self.stamina=(val)
        @@stamina = val
      end

      # Retrieves the character's reflex
      # @return [Integer] The reflex of the character.
      def self.reflex
        @@reflex
      end

      # Sets the character's reflex
      # @param val [Integer] The reflex to set for the character
      # @return [void]
      def self.reflex=(val)
        @@reflex = val
      end

      # Retrieves the character's agility
      # @return [Integer] The agility of the character.
      def self.agility
        @@agility
      end

      # Sets the character's agility
      # @param val [Integer] The agility to set for the character
      # @return [void]
      def self.agility=(val)
        @@agility = val
      end

      # Retrieves the character's intelligence
      # @return [Integer] The intelligence of the character.
      def self.intelligence
        @@intelligence
      end

      # Sets the character's intelligence
      # @param val [Integer] The intelligence to set for the character
      # @return [void]
      def self.intelligence=(val)
        @@intelligence = val
      end

      # Retrieves the character's wisdom
      # @return [Integer] The wisdom of the character.
      def self.wisdom
        @@wisdom
      end

      # Sets the character's wisdom
      # @param val [Integer] The wisdom to set for the character
      # @return [void]
      def self.wisdom=(val)
        @@wisdom = val
      end

      # Retrieves the character's discipline
      # @return [Integer] The discipline of the character.
      def self.discipline
        @@discipline
      end

      # Sets the character's discipline
      # @param val [Integer] The discipline to set for the character
      # @return [void]
      def self.discipline=(val)
        @@discipline = val
      end

      # Retrieves the character's charisma
      # @return [Integer] The charisma of the character.
      def self.charisma
        @@charisma
      end

      # Sets the character's charisma
      # @param val [Integer] The charisma to set for the character
      # @return [void]
      def self.charisma=(val)
        @@charisma = val
      end

      # Retrieves the character's favors
      # @return [Integer] The favors of the character.
      def self.favors
        @@favors
      end

      # Sets the character's favors
      # @param val [Integer] The favors to set for the character
      # @return [void]
      def self.favors=(val)
        @@favors = val
      end

      # Retrieves the character's TDPS
      # @return [Integer] The TDPS of the character.
      def self.tdps
        @@tdps
      end

      # Sets the character's TDPS
      # @param val [Integer] The TDPS to set for the character
      # @return [void]
      def self.tdps=(val)
        @@tdps = val
      end

      # Retrieves the character's luck
      # @return [Integer] The luck of the character.
      def self.luck
        @@luck
      end

      # Sets the character's luck
      # @param val [Integer] The luck to set for the character
      # @return [void]
      def self.luck=(val)
        @@luck = val
      end

      # Retrieves the character's balance
      # @return [Integer] The balance of the character.
      def self.balance
        @@balance
      end

      # Sets the character's balance
      # @param val [Integer] The balance to set for the character
      # @return [void]
      def self.balance=(val)
        @@balance = val
      end

      # Retrieves the character's encumbrance
      # @return [Integer, nil] The encumbrance of the character or nil if not set.
      def self.encumbrance
        @@encumbrance
      end

      # Sets the character's encumbrance
      # @param val [Integer] The encumbrance to set for the character
      # @return [void]
      def self.encumbrance=(val)
        @@encumbrance = val
      end

      # Retrieves the character's name from XMLData
      # @return [String] The name of the character.
      def self.name
        XMLData.name
      end

      # Retrieves the character's health from XMLData
      # @return [Integer] The health of the character.
      def self.health
        XMLData.health
      end

      # Retrieves the character's mana from XMLData
      # @return [Integer] The mana of the character.
      def self.mana
        XMLData.mana
      end

      # Retrieves the character's fatigue from XMLData
      # @return [Integer] The fatigue of the character.
      def self.fatigue
        XMLData.stamina
      end

      # Retrieves the character's spirit from XMLData
      # @return [Integer] The spirit of the character.
      def self.spirit
        XMLData.spirit
      end

      # Retrieves the character's concentration from XMLData
      # @return [Integer] The concentration of the character.
      def self.concentration
        XMLData.concentration
      end

      # Determines the character's native mana type based on their guild
      # @return [String, nil] The native mana type or nil if not applicable.
      def self.native_mana
        case DRStats.guild
        when 'Necromancer'
          'arcane'
        when 'Barbarian', 'Thief'
          nil
        when 'Moon Mage', 'Trader'
          'lunar'
        when 'Warrior Mage', 'Bard'
          'elemental'
        when 'Cleric', 'Paladin'
          'holy'
        when 'Empath', 'Ranger'
          'life'
        end
      end

      # Serializes the character's stats into an array
      # @return [Array] An array containing the serialized stats.
      def self.serialize
        [@@race, @@guild, @@gender, @@age, @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance]
      end

      # Loads character stats from a serialized array
      # @param array [Array] The array containing serialized stats
      # @return [void]
      def self.load_serialized=(array)
        @@race, @@guild, @@gender, @@age = array[0..3]
        @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance = array[5..12]
      end

      # Checks if the character's guild is Barbarian
      # @return [Boolean] True if the character is a Barbarian, false otherwise.
      def self.barbarian?
        @@guild == 'Barbarian'
      end

      # Checks if the character's guild is Bard
      # @return [Boolean] True if the character is a Bard, false otherwise.
      def self.bard?
        @@guild == 'Bard'
      end

      # Checks if the character's guild is Cleric
      # @return [Boolean] True if the character is a Cleric, false otherwise.
      def self.cleric?
        @@guild == 'Cleric'
      end

      # Checks if the character's guild is Commoner
      # @return [Boolean] True if the character is a Commoner, false otherwise.
      def self.commoner?
        @@guild == 'Commoner'
      end

      # Checks if the character's guild is Empath
      # @return [Boolean] True if the character is an Empath, false otherwise.
      def self.empath?
        @@guild == 'Empath'
      end

      # Checks if the character's guild is Moon Mage
      # @return [Boolean] True if the character is a Moon Mage, false otherwise.
      def self.moon_mage?
        @@guild == 'Moon Mage'
      end

      # Checks if the character's guild is Necromancer
      # @return [Boolean] True if the character is a Necromancer, false otherwise.
      def self.necromancer?
        @@guild == 'Necromancer'
      end

      # Checks if the character's guild is Paladin
      # @return [Boolean] True if the character is a Paladin, false otherwise.
      def self.paladin?
        @@guild == 'Paladin'
      end

      # Checks if the character's guild is Ranger
      # @return [Boolean] True if the character is a Ranger, false otherwise.
      def self.ranger?
        @@guild == 'Ranger'
      end

      # Checks if the character's guild is Thief
      # @return [Boolean] True if the character is a Thief, false otherwise.
      def self.thief?
        @@guild == 'Thief'
      end

      # Checks if the character's guild is Trader
      # @return [Boolean] True if the character is a Trader, false otherwise.
      def self.trader?
        @@guild == 'Trader'
      end

      # Checks if the character's guild is Warrior Mage
      # @return [Boolean] True if the character is a Warrior Mage, false otherwise.
      def self.warrior_mage?
        @@guild == 'Warrior Mage'
      end
    end
  end
end
