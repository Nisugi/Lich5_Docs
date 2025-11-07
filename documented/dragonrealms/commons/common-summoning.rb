# Provides functionality for the Lich project
# @example Using the Lich module
#   Lich::DragonRealms::DRCS.summon_weapon
module Lich
  module DragonRealms
    module DRCS
      module_function

      # Summons a weapon based on the provided parameters.
      # @param moon [Object, nil] The moon phase (optional).
      # @param element [String, nil] The element of the weapon (optional).
      # @param ingot [String, nil] The type of ingot to use (optional).
      # @param skill [String, nil] The skill level for summoning (optional).
      # @return [void]
      # @raise [StandardError] If unable to summon a weapon.
      # @example Summoning a weapon
      #   summon_weapon("full", "fire", "iron", "sword")
      def summon_weapon(moon = nil, element = nil, ingot = nil, skill = nil)
        if DRStats.moon_mage?
          DRCMM.hold_moon_weapon?
        elsif DRStats.warrior_mage?
          get_ingot(ingot, true)
          case DRC.bput("summon weapon #{element} #{skill}", 'You lack the elemental charge', 'you draw out')
          when 'You lack the elemental charge'
            summon_admittance
            summon_weapon(moon, element, nil, skill)
          end
          stow_ingot(ingot)
        else
          echo "Unable to summon weapons as a #{DRStats.guild}"
        end
        pause 1
        waitrt?
        DRC.fix_standing
      end

      # Retrieves the specified ingot for use in summoning.
      # @param ingot [String] The type of ingot to retrieve.
      # @param swap [Boolean] Indicates if the ingot should be swapped.
      # @return [void]
      # @note This method does nothing if the ingot is nil.
      # @example Getting an ingot
      #   get_ingot("iron", true)
      def get_ingot(ingot, swap)
        return unless ingot

        DRC.bput("get my #{ingot} ingot", 'You get')
        DRC.bput('swap', 'You move') if swap
      end

      # Stows the specified ingot back into inventory.
      # @param ingot [String] The type of ingot to stow.
      # @return [void]
      # @note This method does nothing if the ingot is nil.
      # @example Stowing an ingot
      #   stow_ingot("iron")
      def stow_ingot(ingot)
        return unless ingot

        DRC.bput("stow my #{ingot} ingot", 'You put')
      end

      # Breaks the summoned weapon if it exists.
      # @param item [String, nil] The item to break.
      # @return [void]
      # @note This method does nothing if the item is nil.
      # @example Breaking a summoned weapon
      #   break_summoned_weapon("moonblade")
      def break_summoned_weapon(item)
        return if item.nil?

        DRC.bput("break my #{item}", 'Focusing your will', 'disrupting its matrix', "You can't break", "Break what")
      end

      # Shapes the summoned weapon to a specified skill.
      # @param skill [String] The skill to shape the weapon.
      # @param ingot [String, nil] The type of ingot to use (optional).
      # @return [void]
      # @raise [StandardError] If unable to shape the weapon.
      # @example Shaping a summoned weapon
      #   shape_summoned_weapon("Staves", "iron")
      def shape_summoned_weapon(skill, ingot = nil)
        if DRStats.moon_mage?
          skill_to_shape = { 'Staves' => 'blunt', 'Twohanded Edged' => 'huge', 'Large Edged' => 'heavy', 'Small Edged' => 'normal' }
          shape = skill_to_shape[skill]
          if DRCMM.hold_moon_weapon?
            DRC.bput("shape #{identify_summoned_weapon} to #{shape}", 'you adjust the magic that defines its shape', 'already has', 'You fumble around')
          end
        elsif DRStats.warrior_mage?
          get_ingot(ingot, false)
          case DRC.bput("shape my #{identify_summoned_weapon} to #{skill}", 'You lack the elemental charge', 'You reach out', 'You fumble around', "You don't know how to manipulate your weapon in that way")
          when 'You lack the elemental charge'
            summon_admittance
            shape_summoned_weapon(skill, nil)
          end
          stow_ingot(ingot)
        else
          echo "Unable to shape weapons as a #{DRStats.guild}"
        end
        pause 1
        waitrt?
      end

      # Returns what kind of summoned weapon you're holding.
      # Will be the <adj> <noun> like 'red-hot moonblade' or 'electric sword.
      # Identifies the type of summoned weapon currently held.
      # @return [String, nil] The description of the summoned weapon or nil if none.
      # @example Identifying a summoned weapon
      #   weapon = identify_summoned_weapon
      def identify_summoned_weapon
        if DRStats.moon_mage?
          return DRC.right_hand if DRCMM.is_moon_weapon?(DRC.right_hand)
          return DRC.left_hand  if DRCMM.is_moon_weapon?(DRC.left_hand)
        elsif DRStats.warrior_mage?
          weapon_regex = /^You tap (?:a|an|some)(?:[\w\s\-]+)((stone|fiery|icy|electric) [\w\s\-]+) that you are holding.$/
          # For a two-worded weapon like 'short sword' the only way to know
          # which element it was summoned with is by tapping it. That's the only
          # way we can infer if it's a summoned sword or a regular one.
          # However, the <adj> <noun> of the item we return must be what's in
          # their hands, not what the regex matches in the tap.
          return DRC.right_hand if DRCI.tap(DRC.right_hand) =~ weapon_regex
          return DRC.left_hand if DRCI.tap(DRC.left_hand) =~ weapon_regex
        else
          echo "Unable to summon weapons as a #{DRStats.guild}"
        end
      end

      # Turns the summoned weapon in the specified direction.
      # @return [void]
      # @raise [StandardError] If unable to turn the weapon.
      # @example Turning a summoned weapon
      #   turn_summoned_weapon
      def turn_summoned_weapon
        case DRC.bput("turn my #{GameObj.right_hand.noun}", 'You lack the elemental charge', 'You reach out')
        when 'You lack the elemental charge'
          summon_admittance
          turn_summoned_weapon
        end
        pause 1
        waitrt?
      end

      # Pushes the summoned weapon forward.
      # @return [void]
      # @raise [StandardError] If unable to push the weapon.
      # @example Pushing a summoned weapon
      #   push_summoned_weapon
      def push_summoned_weapon
        case DRC.bput("push my #{GameObj.right_hand.noun}", 'You lack the elemental charge', 'Closing your eyes', 'That\'s as')
        when 'You lack the elemental charge'
          summon_admittance
          push_summoned_weapon
        end
        pause 1
        waitrt?
      end

      # Pulls the summoned weapon back.
      # @return [void]
      # @raise [StandardError] If unable to pull the weapon.
      # @example Pulling a summoned weapon
      #   pull_summoned_weapon
      def pull_summoned_weapon
        case DRC.bput("pull my #{GameObj.right_hand.noun}", 'You lack the elemental charge', 'Closing your eyes', 'That\'s as')
        when 'You lack the elemental charge'
          summon_admittance
          pull_summoned_weapon
        end
        pause 1
        waitrt?
      end

      # Handles the admittance process for summoning.
      # @return [void]
      # @raise [StandardError] If unable to summon admittance.
      # @example Summoning admittance
      #   summon_admittance
      def summon_admittance
        case DRC.bput('summon admittance', 'You align yourself to it', 'further increasing your proximity', 'Going any further while in this plane would be fatal', 'Summon allows Warrior Mages to draw', 'You are a bit too distracted')
        when 'You are a bit too distracted'
          DRC.retreat
          summon_admittance
        end
        pause 1
        waitrt?
        DRC.fix_standing
      end
    end
  end
end
