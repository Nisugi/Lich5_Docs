module Lich
  module DragonRealms
    # Validates characters in the DragonRealms game.
    # This class handles the validation of characters, sending messages, and managing their states.
    # @example Creating a character validator
    #   validator = Lich::DragonRealms::CharacterValidator.new(true, false, true, "Hero")
    class CharacterValidator
      # Initializes a new CharacterValidator instance.
      # @param announce [Boolean] Whether to announce the character's presence.
      # @param sleep [Boolean] Whether the character is sleeping.
      # @param greet [Boolean] Whether to greet the character.
      # @param name [String] The name of the character.
      # @return [CharacterValidator]
      # @example
      #   validator = CharacterValidator.new(true, false, true, "Hero")
      def initialize(announce, sleep, greet, name)
        waitrt?
        fput('sleep') if sleep

        @lnet = (Script.running + Script.hidden).find { |val| val.name == 'lnet' }
        @validated_characters = []
        @greet = greet
        @name = name

        @lnet.unique_buffer.push("chat #{@name} is up and running in room #{Room.current.id}! Whisper me 'help' for more details.") if announce
      end

      # Sends the Slack token to a specified character.
      # @param character [String] The name of the character to send the token to.
      # @return [void]
      # @example
      #   validator.send_slack_token("Hero")
      def send_slack_token(character)
        message = "slack_token: #{UserVars.slack_token || 'Not Found'}"
        echo "Attempting to DM #{character} with message: #{message}"
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end

      # Validates a character's existence.
      # @param character [String] The name of the character to validate.
      # @return [void]
      # @example
      #   validator.validate("Hero")
      def validate(character)
        return if valid?(character)

        echo "Attempting to validate: #{character}"
        @lnet.unique_buffer.push("who #{character}")
      end

      # Confirms a character's validation and optionally greets them.
      # @param character [String] The name of the character to confirm.
      # @return [void]
      # @example
      #   validator.confirm("Hero")
      def confirm(character)
        return if valid?(character)

        echo "Successfully validated: #{character}"
        @validated_characters << character

        return unless @greet

        put "whisper #{character} Hi! I'm your friendly neighborhood #{@name}. Whisper me 'help' for more details. Don't worry, I've memorized your name so you won't see this message again."
      end

      # Checks if a character is validated.
      # @param character [String] The name of the character to check.
      # @return [Boolean] Returns true if the character is validated, false otherwise.
      # @example
      #   validator.valid?("Hero")
      def valid?(character)
        @validated_characters.include?(character)
      end

      # Sends the current bank balance to a specified character.
      # @param character [String] The name of the character to send the balance to.
      # @param balance [Numeric] The current balance to send.
      # @return [void]
      # @example
      #   validator.send_bankbot_balance("Hero", 100)
      def send_bankbot_balance(character, balance)
        message = "Current Balance: #{balance}"
        echo "Attempting to DM #{character} with message: #{message}"
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end

      # Sends the current location to a specified character.
      # @param character [String] The name of the character to send the location to.
      # @return [void]
      # @example
      #   validator.send_bankbot_location("Hero")
      def send_bankbot_location(character)
        message = "Current Location: #{Room.current.id}"
        echo "Attempting to DM #{character} with message: #{message}"
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end

      # Sends help messages to a specified character.
      # @param character [String] The name of the character to send help messages to.
      # @param messages [Array<String>] An array of messages to send.
      # @return [void]
      # @example
      #   validator.send_bankbot_help("Hero", ["Help message 1", "Help message 2"])
      def send_bankbot_help(character, messages)
        messages.each do |message|
          echo "Attempting to DM #{character} with message: #{message}"
          @lnet.unique_buffer.push("chat to #{character} #{message}")
        end
      end

      # Checks if a character is currently in the game.
      # @param character [String] The name of the character to check.
      # @return [Boolean] Returns true if the character is in the game, false otherwise.
      # @example
      #   validator.in_game?("Hero")
      def in_game?(character)
        DRC.bput("find #{character}", 'There are no adventurers in the realms that match the names specified', "^  #{character}.$") == "  #{character}."
      end
    end
  end
end
