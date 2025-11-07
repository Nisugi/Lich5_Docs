# Provides common account functionalities for the Lich5 project
# @example Usage
#   Lich::Common::Account.name = "Player1"
module Lich
  module Common
    module Account
      @@name ||= nil
      @@subscription ||= nil
      @@game_code ||= nil
      @@members ||= {}
      @@character ||= nil

      # Retrieves the name of the account
      # @return [String] the account name
      # @example
      #   account_name = Lich::Common::Account.name
      def self.name
        @@name
      end

      # Sets the name of the account
      # @param value [String] The name to set for the account
      # @return [String] the set account name
      # @example
      #   Lich::Common::Account.name = "Player1"
      def self.name=(value)
        @@name = value
      end

      # Retrieves the character associated with the account
      # @return [Object] the character object
      # @example
      #   character = Lich::Common::Account.character
      def self.character
        @@character
      end

      # Sets the character for the account
      # @param value [Object] The character object to associate with the account
      # @return [Object] the set character object
      # @example
      #   Lich::Common::Account.character = my_character
      def self.character=(value)
        @@character = value
      end

      # Retrieves the subscription type of the account
      # @return [String] the subscription type
      # @example
      #   subscription_type = Lich::Common::Account.subscription
      def self.subscription
        @@subscription
      end

      # Retrieves the type of account based on game data
      # @return [String, nil] the account type or nil if not applicable
      # @example
      #   account_type = Lich::Common::Account.type
      def self.type
        if XMLData.game.is_a?(String) && XMLData.game =~ /^GS/
          Infomon.get("account.type")
        end
      end

      # Sets the subscription type for the account
      # @param value [String] The subscription type to set (NORMAL, PREMIUM, TRIAL, INTERNAL, FREE)
      # @return [String] the set subscription type
      # @example
      #   Lich::Common::Account.subscription = "PREMIUM"
      def self.subscription=(value)
        if value =~ /(NORMAL|PREMIUM|TRIAL|INTERNAL|FREE)/
          @@subscription = Regexp.last_match(1)
        end
      end

      # Retrieves the game code associated with the account
      # @return [String] the game code
      # @example
      #   game_code = Lich::Common::Account.game_code
      def self.game_code
        @@game_code
      end

      # Sets the game code for the account
      # @param value [String] The game code to set
      # @return [String] the set game code
      # @example
      #   Lich::Common::Account.game_code = "GS123"
      def self.game_code=(value)
        @@game_code = value
      end

      # Retrieves the members associated with the account
      # @return [Hash] a hash of member codes and names
      # @example
      #   members = Lich::Common::Account.members
      def self.members
        @@members
      end

      # Sets the members for the account
      # @param value [String] A formatted string containing member codes and names
      # @return [Hash] the set members
      # @example
      #   Lich::Common::Account.members = "C\t123\t456\t789\t012\tJohn\tDoe"
      def self.members=(value)
        potential_members = {}
        for code_name in value.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
          char_code, char_name = code_name.split("\t")
          potential_members[char_code] = char_name
        end
        @@members = potential_members
      end

      # Retrieves the character names associated with the account
      # @return [Array] an array of character names
      # @example
      #   character_names = Lich::Common::Account.characters
      def self.characters
        @@members.values
      end
    end
  end
end
