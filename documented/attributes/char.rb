# carve out supporting infomon move to lib

module Lich
  module Common
    # Represents a character in the Lich game.
    # This class provides various methods to access character attributes.
    # @example Accessing character name
    #   character_name = Char.name
    class Char
      # Initializes the character (deprecated).
      # @param _blah [Object] Unused parameter.
      # @return [void]
      # @deprecated Char.init is no longer used.
      # @example
      #   Char.init(some_value)
      def Char.init(_blah)
        echo 'Char.init is no longer used. Update or fix your script.'
      end

      # Returns the name of the character.
      # @return [String] The character's name.
      # @example
      #   name = Char.name
      def Char.name
        XMLData.name
      end

      # Returns the current stance of the character.
      # @return [String] The character's stance text.
      # @example
      #   stance = Char.stance
      def Char.stance
        XMLData.stance_text
      end

      # Returns the percentage of the character's stance.
      # @return [Integer] The percentage value of the character's stance.
      # @example
      #   stance_percentage = Char.percent_stance
      def Char.percent_stance
        XMLData.stance_value
      end

      # Returns the encumbrance text of the character.
      # @return [String] The character's encumbrance text.
      # @example
      #   encumbrance = Char.encumbrance
      def Char.encumbrance
        XMLData.encumbrance_text
      end

      # Returns the percentage of the character's encumbrance.
      # @return [Integer] The percentage value of the character's encumbrance.
      # @example
      #   encumbrance_percentage = Char.percent_encumbrance
      def Char.percent_encumbrance
        XMLData.encumbrance_value
      end

      # Returns the current health of the character.
      # @return [Integer] The character's health value.
      # @example
      #   health = Char.health
      def Char.health
        XMLData.health
      end

      # Returns the current mana of the character.
      # @return [Integer] The character's mana value.
      # @example
      #   mana = Char.mana
      def Char.mana
        XMLData.mana
      end

      # Returns the current spirit of the character.
      # @return [Integer] The character's spirit value.
      # @example
      #   spirit = Char.spirit
      def Char.spirit
        XMLData.spirit
      end

      # Returns the current stamina of the character.
      # @return [Integer] The character's stamina value.
      # @example
      #   stamina = Char.stamina
      def Char.stamina
        XMLData.stamina
      end

      # Returns the maximum health of the character.
      # @return [Integer] The character's maximum health value.
      # @example
      #   max_health = Char.max_health
      def Char.max_health
        # Object.module_eval { XMLData.max_health }
        XMLData.max_health
      end

      # Returns the maximum health of the character (deprecated).
      # @return [Integer] The character's maximum health value.
      # @deprecated Use Char.max_health instead.
      # @example
      #   max_health = Char.maxhealth
      def Char.maxhealth
        Lich.deprecated("Char.maxhealth", "Char.max_health", caller[0], fe_log: true)
        Char.max_health
      end

      # Returns the maximum mana of the character.
      # @return [Integer] The character's maximum mana value.
      # @example
      #   max_mana = Char.max_mana
      def Char.max_mana
        Object.module_eval { XMLData.max_mana }
      end

      # Returns the maximum mana of the character (deprecated).
      # @return [Integer] The character's maximum mana value.
      # @deprecated Use Char.max_mana instead.
      # @example
      #   max_mana = Char.maxmana
      def Char.maxmana
        Lich.deprecated("Char.maxmana", "Char.max_mana", caller[0], fe_log: true)
        Char.max_mana
      end

      # Returns the maximum spirit of the character.
      # @return [Integer] The character's maximum spirit value.
      # @example
      #   max_spirit = Char.max_spirit
      def Char.max_spirit
        Object.module_eval { XMLData.max_spirit }
      end

      # Returns the maximum spirit of the character (deprecated).
      # @return [Integer] The character's maximum spirit value.
      # @deprecated Use Char.max_spirit instead.
      # @example
      #   max_spirit = Char.maxspirit
      def Char.maxspirit
        Lich.deprecated("Char.maxspirit", "Char.max_spirit", caller[0], fe_log: true)
        Char.max_spirit
      end

      # Returns the maximum stamina of the character.
      # @return [Integer] The character's maximum stamina value.
      # @example
      #   max_stamina = Char.max_stamina
      def Char.max_stamina
        Object.module_eval { XMLData.max_stamina }
      end

      # Returns the maximum stamina of the character (deprecated).
      # @return [Integer] The character's maximum stamina value.
      # @deprecated Use Char.max_stamina instead.
      # @example
      #   max_stamina = Char.maxstamina
      def Char.maxstamina
        Lich.deprecated("Char.maxstamina", "Char.max_stamina", caller[0], fe_log: true)
        Char.max_stamina
      end

      # Returns the percentage of the character's health.
      # @return [Integer] The percentage value of the character's health.
      # @example
      #   health_percentage = Char.percent_health
      def Char.percent_health
        ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
      end

      # Returns the percentage of the character's mana.
      # @return [Integer] The percentage value of the character's mana.
      # @example
      #   mana_percentage = Char.percent_mana
      def Char.percent_mana
        if XMLData.max_mana == 0
          100
        else
          ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
        end
      end

      # Returns the percentage of the character's spirit.
      # @return [Integer] The percentage value of the character's spirit.
      # @example
      #   spirit_percentage = Char.percent_spirit
      def Char.percent_spirit
        ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
      end

      # Returns the percentage of the character's stamina.
      # @return [Integer] The percentage value of the character's stamina.
      # @example
      #   stamina_percentage = Char.percent_stamina
      def Char.percent_stamina
        if XMLData.max_stamina == 0
          100
        else
          ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
        end
      end

      # Dumps character information (deprecated).
      # @return [void]
      # @deprecated Char.dump_info is no longer used.
      # @example
      #   Char.dump_info
      def Char.dump_info
        echo "Char.dump_info is no longer used. Update or fix your script."
      end

      # Loads character information (deprecated).
      # @param _string [String] Unused parameter.
      # @return [void]
      # @deprecated Char.load_info is no longer used.
      # @example
      #   Char.load_info(some_string)
      def Char.load_info(_string)
        echo "Char.load_info is no longer used. Update or fix your script."
      end

      # Checks if the character responds to a method.
      # @param m [Symbol] The method name to check.
      # @param args [Array] Additional arguments for the method.
      # @return [Boolean] True if the method is supported, false otherwise.
      # @example
      #   supports_method = Char.respond_to?(:some_method)
      def Char.respond_to?(m, *args)
        [Stats, Skills, Spellsong].any? { |k| k.respond_to?(m) } or super(m, *args)
      end

      # Handles missing methods for the character.
      # @param meth [Symbol] The missing method name.
      # @param args [Array] Arguments for the missing method.
      # @return [Object] The result of the method call if found, otherwise raises NoMethodError.
      # @example
      #   result = Char.some_missing_method
      def Char.method_missing(meth, *args)
        polyfill = [Stats, Skills, Spellsong].find { |klass|
          klass.respond_to?(meth, *args)
        }
        if polyfill
          Lich.deprecated("Char.#{meth}", "#{polyfill}.#{meth}", caller[0])
          return polyfill.send(meth, *args)
        end
        super(meth, *args)
      end

      # Provides character information (deprecated).
      # @return [void]
      # @deprecated Char.info is no longer supported.
      # @example
      #   Char.info
      def Char.info
        echo "Char.info is no longer supported. Update or fix your script."
      end

      # Provides character skills information (deprecated).
      # @return [void]
      # @deprecated Char.skills is no longer supported.
      # @example
      #   Char.skills
      def Char.skills
        echo "Char.skills is no longer supported. Update or fix your script."
      end

      # Returns the citizenship of the character if applicable.
      # @return [String, nil] The character's citizenship or nil if not applicable.
      # @example
      #   citizenship = Char.citizenship
      def Char.citizenship
        Infomon.get('citizenship') if XMLData.game =~ /^GS/
      end

      # Sets the citizenship of the character (deprecated).
      # @param _val [Object] The value to set.
      # @return [void]
      # @deprecated Updating via Char.citizenship is no longer supported.
      # @example
      #   Char.citizenship = "New Citizenship"
      def Char.citizenship=(_val)
        echo "Updating via Char.citizenship is no longer supported. Update or fix your script."
      end

      # Returns the 'che' attribute of the character if applicable.
      # @return [String, nil] The character's 'che' value or nil if not applicable.
      # @example
      #   che_value = Char.che
      def Char.che
        Infomon.get('che') if XMLData.game =~ /^GS/
      end
    end
  end
end
