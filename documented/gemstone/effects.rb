module Lich
  module Gemstone
    module Effects
      # Manages a collection of effects in the Lich system.
      # This class includes methods to handle the registration and retrieval of effects.
      # @example Creating a new effect registry
      #   registry = Lich::Gemstone::Effects::Registry.new("Active Effects")
      class Registry
        include Enumerable

        # Initializes a new Registry instance.
        # @param dialog [String] The name of the dialog associated with this registry.
        # @return [Registry]
        def initialize(dialog)
          @dialog = dialog
        end

        # Converts the registry to a hash representation.
        # @return [Hash] A hash of effects associated with the dialog.
        def to_h
          XMLData.dialogs.fetch(@dialog, {})
        end

        # Iterates over each effect in the registry.
        # @yield [key, value] Yields each key-value pair in the registry.
        # @return [Enumerator] An enumerator if no block is given.
        def each()
          to_h.each { |k, v| yield(k, v) }
        end

        # Retrieves the expiration time of a given effect.
        # @param effect [String, Regexp] The effect to check for expiration.
        # @return [Integer] The expiration time in seconds since epoch, or 0 if not found.
        def expiration(effect)
          if effect.is_a?(Regexp)
            to_h.find { |k, _v| k.to_s =~ effect }[1] || 0
          else
            to_h.fetch(effect, 0)
          end
        end

        # Checks if a given effect is currently active.
        # @param effect [String, Regexp] The effect to check.
        # @return [Boolean] True if the effect is active, false otherwise.
        def active?(effect)
          expiration(effect).to_f > Time.now.to_f
        end

        # Calculates the time left for a given effect.
        # @param effect [String, Regexp] The effect to check.
        # @return [Float] The time left in minutes, or the expiration time if not active.
        def time_left(effect)
          if expiration(effect) != 0
            ((expiration(effect) - Time.now) / 60.to_f)
          else
            expiration(effect)
          end
        end
      end

      # A registry for active spells.
      Spells    = Registry.new("Active Spells")
      # A registry for buffs.
      Buffs     = Registry.new("Buffs")
      # A registry for debuffs.
      Debuffs   = Registry.new("Debuffs")
      # A registry for cooldowns.
      Cooldowns = Registry.new("Cooldowns")

      # Displays the current effects in a formatted table.
      # @return [void]
      # @example Displaying the current effects
      #   Lich::Gemstone::Effects.display
      def self.display
        effect_out = Terminal::Table.new :headings => ["ID", "Type", "Name", "Duration"]
        titles = ["Spells", "Cooldowns", "Buffs", "Debuffs"]
        existing_spell_nums = []
        active_spells = Spell.active
        active_spells.each { |s| existing_spell_nums << s.num }
        circle = nil
        [Effects::Spells, Effects::Cooldowns, Effects::Buffs, Effects::Debuffs].each { |effect|
          title = titles.shift
          id_effects = effect.to_h.select { |k, _v| k.is_a?(Integer) }
          text_effects = effect.to_h.reject { |k, _v| k.is_a?(Integer) }
          if id_effects.length != text_effects.length
            # has spell names disabled
            text_effects = id_effects
          end
          if id_effects.length == 0
            effect_out.add_row ["", title, "No #{title.downcase} found!", ""]
          else
            id_effects.each { |sn, end_time|
              stext = text_effects.shift[0]
              duration = ((end_time - Time.now) / 60.to_f)
              if duration < 0
                next
              elsif duration > 86400
                duration = "Indefinite"
              else
                duration = duration.as_time
              end
              if Spell[sn].circlename && circle != Spell[sn].circlename && title == 'Spells'
                circle = Spell[sn].circlename
              end
              effect_out.add_row [sn, title, stext, duration]
              existing_spell_nums.delete_if { |s| Spell[s].name =~ /#{Regexp.escape(stext)}/ || stext =~ /#{Regexp.escape(Spell[s].name)}/ || s == sn }
            }
          end
          effect_out.add_separator unless title == 'Debuffs' && existing_spell_nums.empty?
        }
        existing_spell_nums.each { |sn|
          effect_out.add_row [sn, "Other", Spell[sn].name, (Spell[sn].timeleft.as_time)]
        }
        Lich::Messaging.mono(effect_out.to_s)
      end
    end
  end
end
