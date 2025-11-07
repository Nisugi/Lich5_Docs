# API for char Status
# todo: should include jaws / condemn / others?

require "ostruct"

# Contains the Lich module for the Gemstone project
# This module serves as a namespace for various functionalities related to the Lich project.
# @example Including the Lich module
#   include Lich
module Lich
  # Contains functionalities specific to the Gemstone game
  # This module encapsulates all game-related features and interactions.
  # @example Using the Gemstone module
  #   include Lich::Gemstone
  module Gemstone
    # Provides methods to check character status in the game
    # This module includes various methods to determine the current status of a character.
    # @example Checking character status
    #   Lich::Gemstone::Status.thorned?
    module Status
      # Checks if the character is thorned
      # @return [Boolean] true if the character is thorned, false otherwise
      # @example Checking if a character is thorned
      #   Lich::Gemstone::Status.thorned?
      def self.thorned? # added 2024-09-08
        (Infomon.get_bool("status.thorned") && Effects::Debuffs.active?(/Wall of Thorns Poison [1-5]/))
      end

      # Checks if the character is bound
      # @return [Boolean] true if the character is bound, false otherwise
      # @example Checking if a character is bound
      #   Lich::Gemstone::Status.bound?
      def self.bound?
        Infomon.get_bool("status.bound") && (Effects::Debuffs.active?('Bind') || Effects::Debuffs.active?(214))
      end

      # Checks if the character is calmed
      # @return [Boolean] true if the character is calmed, false otherwise
      # @example Checking if a character is calmed
      #   Lich::Gemstone::Status.calmed?
      def self.calmed?
        Infomon.get_bool("status.calmed") && (Effects::Debuffs.active?('Calm') || Effects::Debuffs.active?(201))
      end

      # Checks if the character is in a cutthroat state
      # @return [Boolean] true if the character is cutthroat, false otherwise
      # @example Checking if a character is cutthroat
      #   Lich::Gemstone::Status.cutthroat?
      def self.cutthroat?
        Infomon.get_bool("status.cutthroat") && Effects::Debuffs.active?('Major Bleed')
      end

      # Checks if the character is silenced
      # @return [Boolean] true if the character is silenced, false otherwise
      # @example Checking if a character is silenced
      #   Lich::Gemstone::Status.silenced?
      def self.silenced?
        Infomon.get_bool("status.silenced") && Effects::Debuffs.active?('Silenced')
      end

      # Checks if the character is sleeping
      # @return [Boolean] true if the character is sleeping, false otherwise
      # @example Checking if a character is sleeping
      #   Lich::Gemstone::Status.sleeping?
      def self.sleeping?
        Infomon.get_bool("status.sleeping") && (Effects::Debuffs.active?('Sleep') || Effects::Debuffs.active?(501))
      end

      # deprecate these in global_defs after warning, consider bringing other status maps over
      # Checks if the character is webbed
      # @return [Boolean] true if the character is webbed, false otherwise
      # @example Checking if a character is webbed
      #   Lich::Gemstone::Status.webbed?
      def self.webbed?
        XMLData.indicator['IconWEBBED'] == 'y'
      end

      # Checks if the character is dead
      # @return [Boolean] true if the character is dead, false otherwise
      # @example Checking if a character is dead
      #   Lich::Gemstone::Status.dead?
      def self.dead?
        XMLData.indicator['IconDEAD'] == 'y'
      end

      # Checks if the character is stunned
      # @return [Boolean] true if the character is stunned, false otherwise
      # @example Checking if a character is stunned
      #   Lich::Gemstone::Status.stunned?
      def self.stunned?
        XMLData.indicator['IconSTUNNED'] == 'y'
      end

      # Checks if the character is muckled (webbed, dead, stunned, bound, or sleeping)
      # @return [Boolean] true if the character is muckled, false otherwise
      # @example Checking if a character is muckled
      #   Lich::Gemstone::Status.muckled?
      def self.muckled?
        return Status.webbed? || Status.dead? || Status.stunned? || Status.bound? || Status.sleeping?
      end

      # todo: does this serve a purpose?
      # Serializes the status of the character
      # @return [Array<Boolean>] an array of booleans representing various status checks
      # @example Serializing character status
      #   Lich::Gemstone::Status.serialize
      def self.serialize
        [self.bound?, self.calmed?, self.cutthroat?, self.silenced?, self.sleeping?]
      end
    end
  end
end
