# Lich module
# This module serves as a namespace for the Lich project.
module Lich
  # Gemstone module
  # This module contains functionality related to gemstones in the Lich project.
  module Gemstone
    # SK module
    # This module manages the spells known by the SK character class.
    # @example Using the SK module
    #   Lich::Gemstone::SK.add(123)
    #   Lich::Gemstone::SK.list
    module SK
      @sk_known = nil

      # Retrieves the list of known SK spells.
      # @return [Array<String>] An array of known spell numbers as strings.
      # @note This method initializes the known spells if they are not already set.
      # @example
      #   known_spells = Lich::Gemstone::SK.sk_known
      def self.sk_known
        if @sk_known.nil?
          val = DB_Store.read("#{XMLData.game}:#{XMLData.name}", "sk_known")
          if val.nil? || (val.is_a?(Hash) && val.empty?)
            old_settings = DB_Store.read("#{XMLData.game}:#{XMLData.name}", "vars")["sk/known"]
            if old_settings.is_a?(Array)
              val = old_settings
            else
              val = []
            end
            self.sk_known = val
          end
          @sk_known = val unless val.nil?
        end
        return @sk_known
      end

      # Sets the list of known SK spells.
      # @param val [Array<String>] An array of spell numbers to be set as known.
      # @return [Array<String>] The updated list of known spells.
      # @example
      #   Lich::Gemstone::SK.sk_known = ["123", "456"]
      def self.sk_known=(val)
        return @sk_known if @sk_known == val
        DB_Store.save("#{XMLData.game}:#{XMLData.name}", "sk_known", val)
        @sk_known = val
      end

      # Checks if a specific spell is known.
      # @param spell [Object] The spell object to check.
      # @return [Boolean] True if the spell is known, false otherwise.
      # @example
      #   is_known = Lich::Gemstone::SK.known?(some_spell)
      def self.known?(spell)
        self.sk_known if @sk_known.nil?
        @sk_known.include?(spell.num.to_s)
      end

      # Lists the current known SK spells.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.list
      def self.list
        respond "Current SK Spells: #{@sk_known.inspect}"
        respond ""
      end

      # Provides help information for managing SK spells.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.help
      def self.help
        respond "   Script to add SK spells to be known and used with Spell API calls."
        respond ""
        respond "   ;sk add <SPELL_NUMBER>  - Add spell number to saved list"
        respond "   ;sk rm <SPELL_NUMBER>   - Remove spell number from saved list"
        respond "   ;sk list                - Show all currently saved SK spell numbers"
        respond "   ;sk help                - Show this menu"
        respond ""
      end

      # Adds spell numbers to the list of known SK spells.
      # @param numbers [Array<Integer>] The spell numbers to add.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.add(123, 456)
      def self.add(*numbers)
        self.sk_known = (@sk_known + numbers).uniq
        self.list
      end

      # Removes spell numbers from the list of known SK spells.
      # @param numbers [Array<Integer>] The spell numbers to remove.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.remove(123)
      def self.remove(*numbers)
        self.sk_known = (@sk_known - numbers).uniq
        self.list
      end

      # Main entry point for managing SK spells based on the action provided.
      # @param action [Symbol] The action to perform (:add, :rm, :list, or :help).
      # @param spells [String, nil] The spell numbers to add or remove, as a space-separated string.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.main(:add, "123 456")
      def self.main(action = help, spells = nil)
        self.sk_known if @sk_known.nil?
        action = action.to_sym
        spells = spells.split(" ").uniq
        case action
        when :add
          self.add(*spells) unless spells.empty?
          self.help if spells.empty?
        when :rm
          self.remove(*spells) unless spells.empty?
          self.help if spells.empty?
        when :list
          self.list
        else
          self.help
        end
      end
    end
  end
end
