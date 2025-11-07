# The Lich module
# This module serves as a namespace for the DragonRealms game.
# @example Using the Lich module
#   include Lich
module Lich
  # The DragonRealms module
  # This module contains functionality specific to the DragonRealms game.
  # @example Including DragonRealms
  #   include Lich::DragonRealms
  module DragonRealms
    # The DRCTH module
    # This module provides methods related to the cleric theurgy in DragonRealms.
    # @example Using DRCTH methods
    #   DRCTH.has_holy_water?(container, holder)
    module DRCTH
      module_function

      # List of items used by clerics in the game.
      # @return [Array<String>] An array of cleric item names.
      CLERIC_ITEMS = [
        'holy water', 'holy oil', 'wine', 'incense', 'flint', 'chamomile', 'sage', 'jalbreth balm'
      ] unless defined?(CLERIC_ITEMS)

      # List of error messages related to commune actions.
      # @return [Array<String>] An array of commune error messages.
      COMMUNE_ERRORS = [
        'As you commune you sense that the ground is already consecrated.',
        'You stop as you realize that you have attempted a commune',
        'completed this commune too recently'
      ] unless defined?(COMMUNE_ERRORS)

      # List of devotion levels messages for clerics.
      # @return [Array<String>] An array of devotion level messages.
      DEVOTION_LEVELS = [
        'You sense nothing special from your communing',
        'You feel unclean and unworthy',
        'You close your eyes and start to concentrate',
        'You call out to your god, but there is no answer',
        'After a moment, you sense that your god is barely aware of you',
        'After a moment, you sense that your efforts have not gone unnoticed',
        'After a moment, you sense a distinct link between you and your god',
        'After a moment, you sense that your god is aware of your devotion',
        'After a moment, you sense that your god knows your name',
        'After a moment, you sense that your god is pleased with your devotion',
        'After a moment, you see a vision of your god, though the visage is cloudy',
        'After a moment, you sense a slight pressure on your shoulder',
        'After a moment, you see a silent vision of your god',
        'After a moment, you see a vision of your god who calls to you by name, "Come here, my child',
        'After a moment, you see a vision of your god who calls to you by name, "My child, though you may',
        'After a moment, you see a crystal-clear vision of your god who speaks slowly and deliberately',
        'After a moment, you feel a clear presence like a warm blanket covering you'
      ] unless defined?(DEVOTION_LEVELS)

      # Checks if the specified container has holy water.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param water_holder [String] The item holder for holy water.
      # @return [Boolean] Returns true if holy water is present, false otherwise.
      # @example Checking for holy water
      #   has_holy_water?(supply_container, "my water holder")
      def has_holy_water?(theurgy_supply_container, water_holder)
        return false unless DRCI.get_item?(water_holder, theurgy_supply_container)

        has_water = DRCI.inside?('holy water', water_holder)
        DRCI.put_away_item?(water_holder, theurgy_supply_container)
        return has_water
      end

      # Checks if the specified container has flint.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [Boolean] Returns true if flint is present, false otherwise.
      # @example Checking for flint
      #   has_flint?(supply_container)
      def has_flint?(theurgy_supply_container)
        DRCI.have_item_by_look?('flint', theurgy_supply_container)
      end

      # Checks if the specified container has holy oil.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [Boolean] Returns true if holy oil is present, false otherwise.
      # @example Checking for holy oil
      #   has_holy_oil?(supply_container)
      def has_holy_oil?(theurgy_supply_container)
        DRCI.have_item_by_look?('holy oil', theurgy_supply_container)
      end

      # Checks if the specified container has incense.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [Boolean] Returns true if incense is present, false otherwise.
      # @example Checking for incense
      #   has_incense?(supply_container)
      def has_incense?(theurgy_supply_container)
        DRCI.have_item_by_look?('incense', theurgy_supply_container)
      end

      # Checks if the specified container has jalbreth balm.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [Boolean] Returns true if jalbreth balm is present, false otherwise.
      # @example Checking for jalbreth balm
      #   has_jalbreth_balm?(supply_container)
      def has_jalbreth_balm?(theurgy_supply_container)
        DRCI.have_item_by_look?('jalbreth balm', theurgy_supply_container)
      end

      # Determines if buying a cleric item requires a blessing.
      # @param town [String] The name of the town.
      # @param item_name [String] The name of the item to check.
      # @return [Boolean, nil] Returns true if a blessing is needed, false if not, or nil if data is unavailable.
      # @example Checking if a blessing is required
      #   buying_cleric_item_requires_bless?("town_name", "item_name")
      def buying_cleric_item_requires_bless?(town, item_name)
        town_theurgy_data = get_data('theurgy')[town]
        return if town_theurgy_data.nil?

        item_shop_data = town_theurgy_data["#{item_name}_shop"]
        return if item_shop_data.nil?

        return item_shop_data['needs_bless']
      end

      # Attempts to buy a cleric item from a town's shop.
      # @param town [String] The name of the town.
      # @param item_name [String] The name of the item to buy.
      # @param stackable [Boolean] Indicates if the item is stackable.
      # @param num_to_buy [Integer] The number of items to buy.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [Boolean] Returns true if the purchase was successful, false otherwise.
      # @example Buying a cleric item
      #   buy_cleric_item?("town_name", "item_name", true, 5, supply_container)
      def buy_cleric_item?(town, item_name, stackable, num_to_buy, theurgy_supply_container)
        town_theurgy_data = get_data('theurgy')[town]
        return false if town_theurgy_data.nil?

        item_shop_data = town_theurgy_data["#{item_name}_shop"]
        return false if item_shop_data.nil?

        DRCT.walk_to(item_shop_data['id'])
        if stackable
          num_to_buy.times do
            buy_single_supply(item_name, item_shop_data)
            if DRCI.get_item?(item_name, theurgy_supply_container)
              DRC.bput("combine #{item_name} with #{item_name}", 'You combine', 'You can\'t combine', 'You must be holding')
            end
            # Put this back in the container each cycle so it doesn't interfere
            # with bless of next purchase.
            DRCI.put_away_item?(item_name, @theurgy_supply_container)
          end
        else
          num_to_buy.times do
            buy_single_supply(item_name, item_shop_data)
            DRCI.put_away_item?(item_name, theurgy_supply_container)
          end
        end

        return true
      end

      # Buys a single supply item from the shop.
      # @param item_name [String] The name of the item to buy.
      # @param shop_data [Hash] The data related to the shop.
      # @return [nil] Returns nil after attempting to buy the item.
      # @example Buying a single supply
      #   buy_single_supply("item_name", shop_data)
      def buy_single_supply(item_name, shop_data)
        if shop_data['method']
          send(shop_data['method'])
        else
          DRCT.buy_item(shop_data['id'], item_name)
        end

        return unless shop_data['needs_bless'] && @known_spells.include?('Bless')

        quick_bless_item(item[:name])
      end

      # Casts a quick blessing on the specified item.
      # @param item_name [String] The name of the item to bless.
      # @return [nil] Returns nil after attempting to bless the item.
      # @example Quick blessing an item
      #   quick_bless_item("item_name")
      def quick_bless_item(item_name)
        # use dummy settings object since this isn't complex enough for camb, etc.
        DRCA.cast_spell(
          { 'abbrev' => 'bless', 'mana' => 1, 'prep_time' => 2, 'cast' => "cast my #{item_name}" },
          {}
        )
      end

      # Ensures the cleric's hands are empty before performing actions.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [nil] Returns nil after ensuring hands are empty.
      # @example Emptying cleric hands
      #   empty_cleric_hands(supply_container)
      def empty_cleric_hands(theurgy_supply_container)
        # Adding an explicit glance to ensure we know what's in hands, as
        # items can change
        # [combat-trainer]>snuff my incense
        # You snuff out the fragrant incense.
        # [combat-trainer]>put my fragrant incense in my portal
        # What were you referring to?
        # >glance
        # You glance down to see a steel light spear in your right hand and some burnt incense in your left hand.
        #
        # Which this explicit glance fixes.
        DRC.bput('glance', 'You glance')
        empty_cleric_right_hand(theurgy_supply_container)
        empty_cleric_left_hand(theurgy_supply_container)
      end

      # Empties the cleric's right hand if it contains a cleric item.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [nil] Returns nil after attempting to empty the right hand.
      # @example Emptying right hand
      #   empty_cleric_right_hand(supply_container)
      def empty_cleric_right_hand(theurgy_supply_container)
        return if DRC.right_hand.nil?

        container = CLERIC_ITEMS.any? { |item| DRC.right_hand =~ /#{item}/i } ? theurgy_supply_container : nil
        DRCI.put_away_item?(DRC.right_hand, container)
      end

      # Empties the cleric's left hand if it contains a cleric item.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @return [nil] Returns nil after attempting to empty the left hand.
      # @example Emptying left hand
      #   empty_cleric_left_hand(supply_container)
      def empty_cleric_left_hand(theurgy_supply_container)
        return if DRC.left_hand.nil?

        container = CLERIC_ITEMS.any? { |item| DRC.left_hand =~ /#{item}/i } ? theurgy_supply_container : nil
        DRCI.put_away_item?(DRC.left_hand, container)
      end

      # Sprinkles holy water on a target.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param water_holder [String] The item holder for holy water.
      # @param target [String] The target to sprinkle holy water on.
      # @return [Boolean] Returns true if successful, false otherwise.
      # @example Sprinkling holy water
      #   sprinkle_holy_water?(supply_container, "my water holder", "target")
      def sprinkle_holy_water?(theurgy_supply_container, water_holder, target)
        unless DRCI.get_item?(water_holder, theurgy_supply_container)
          DRC.message("Can't get #{water_holder} to sprinkle.")
          return false
        end
        unless sprinkle?(water_holder, target)
          DRCI.put_away_item?(water_holder, theurgy_supply_container)
          DRC.message("Couldn't sprinkle holy water.")
          return false
        end
        DRCI.put_away_item?(water_holder, theurgy_supply_container)
        return true
      end

      # Sprinkles holy oil on a target.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param target [String] The target to sprinkle holy oil on.
      # @return [Boolean] Returns true if successful, false otherwise.
      # @example Sprinkling holy oil
      #   sprinkle_holy_oil?(supply_container, "target")
      def sprinkle_holy_oil?(theurgy_supply_container, target)
        unless DRCI.get_item?("holy oil", theurgy_supply_container)
          DRC.message("Can't get holy oil to sprinkle.")
          return false
        end
        unless sprinkle?("oil", target)
          empty_cleric_hands(theurgy_supply_container)
          DRC.message("Couldn't sprinkle holy oil.")
          return false
        end
        empty_cleric_hands(theurgy_supply_container)
        return true
      end

      # Sprinkles holy water on a target without checking for success.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param water_holder [String] The item holder for holy water.
      # @param target [String] The target to sprinkle holy water on.
      # @return [nil] Returns nil after attempting to sprinkle holy water.
      # @example Sprinkling holy water directly
      #   sprinkle_holy_water(supply_container, "my water holder", "target")
      def sprinkle_holy_water(theurgy_supply_container, water_holder, target)
        DRCI.get_item?(water_holder, theurgy_supply_container)
        sprinkle?(water_holder, target)
        DRCI.put_away_item?(water_holder, theurgy_supply_container)
      end

      # Sprinkles holy oil on a target without checking for success.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param target [String] The target to sprinkle holy oil on.
      # @return [nil] Returns nil after attempting to sprinkle holy oil.
      # @example Sprinkling holy oil directly
      #   sprinkle_holy_oil(supply_container, "target")
      def sprinkle_holy_oil(theurgy_supply_container, target)
        DRCI.get_item?('holy oil', theurgy_supply_container)
        sprinkle?('oil', target)
        DRCI.put_away_item?('holy oil', theurgy_supply_container) if DRCI.in_hands?('oil')
      end

      # Performs the action of sprinkling an item on a target.
      # @param item [String] The item to sprinkle.
      # @param target [String] The target to sprinkle on.
      # @return [Boolean] Returns true if the action was successful, false otherwise.
      # @example Sprinkling an item
      #   sprinkle?("holy water", "target")
      def sprinkle?(item, target)
        result = DRC.bput("sprinkle #{item} on #{target}", 'You sprinkle', 'Sprinkle (what|that)', 'What were you referring to')
        result == 'You sprinkle'
      end

      # Applies jalbreth balm to a target.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param target [String] The target to apply the balm to.
      # @return [nil] Returns nil after applying the balm.
      # @example Applying jalbreth balm
      #   apply_jalbreth_balm(supply_container, "target")
      def apply_jalbreth_balm(theurgy_supply_container, target)
        DRCI.get_item?('jalbreth balm', theurgy_supply_container)
        DRC.bput("apply balm to #{target}", '.*')
        DRCI.put_away_item?('jalbreth balm', theurgy_supply_container) if DRCI.in_hands?('balm')
      end

      # Waves incense at a target after ensuring necessary items are available.
      # @param theurgy_supply_container [Object] The container holding the theurgy supplies.
      # @param flint_lighter [String] The item used to light the incense.
      # @param target [String] The target to wave incense at.
      # @return [Boolean] Returns true if successful, false otherwise.
      # @example Waving incense
      #   wave_incense?(supply_container, "my flint", "target")
      def wave_incense?(theurgy_supply_container, flint_lighter, target)
        empty_cleric_hands(theurgy_supply_container)

        unless has_flint?(theurgy_supply_container)
          DRC.message("Can't find flint to light")
          return false
        end

        unless has_incense?(theurgy_supply_container)
          DRC.message("Can't find incense to light")
          return false
        end

        unless DRCI.get_item?(flint_lighter)
          DRC.message("Can't get #{flint_lighter} to light incense")
          return false
        end

        unless DRCI.get_item?('incense', theurgy_supply_container)
          DRC.message("Can't get incense to light")
          empty_cleric_hands(theurgy_supply_container)
          return false
        end

        lighting_attempts = 0
        while DRC.bput('light my incense with my flint', 'nothing happens', 'bursts into flames', 'much too dark in here to do that', 'What were you referring to?') == 'nothing happens'
          waitrt?

          lighting_attempts += 1
          if (lighting_attempts >= 5)
            DRC.message("Can't light your incense for some reason. Tried 5 times, giving up.")
            empty_cleric_hands(theurgy_supply_container)
            return false
          end
        end
        DRC.bput("wave my incense at #{target}", 'You wave')
        DRC.bput('snuff my incense', 'You snuff out') if DRCI.in_hands?('incense')

        DRCI.put_away_item?(flint_lighter)
        empty_cleric_hands(theurgy_supply_container)
        return true
      end

      # Senses the current state of communes.
      # @return [Hash] Returns a hash containing active and recent communes, and readiness status.
      # @example Sensing commune state
      #   state = commune_sense
      def commune_sense
        DRC.bput('commune sense', 'Roundtime:')
        pause 0.5

        commune_ready = true
        active_communes = []
        recent_communes = []

        theurgy_lines = reget(50).map(&:strip)
        theurgy_lines.each do |line|
          case line
          when /You will not be able to open another divine conduit yet/
            commune_ready = false
          when /Tamsine\'s benevolent eyes are upon you/, /The miracle of Tamsine has manifested about you/
            active_communes << 'Tamsine'
          when /You are under the auspices of Kertigen/
            active_communes << 'Kertigen'
          when /Meraud's influence is woven into the area/
            active_communes << 'Meraud'
          when /The waters of Eluned are still in your thoughts/
            recent_communes << 'Eluned'
          when /You have been recently enlightened by Tamsine/
            recent_communes << 'Tamsine'
          when /The sounds of Kertigen\'s forge still ring in your ears/
            recent_communes << 'Kertigen'
          when /You are still captivated by Truffenyi\'s favor/
            recent_communes << 'Truffenyi'
          end
        end

        return {
          'active_communes' => active_communes,
          'recent_communes' => recent_communes,
          'commune_ready'   => commune_ready
        }
      end
    end
  end
end
