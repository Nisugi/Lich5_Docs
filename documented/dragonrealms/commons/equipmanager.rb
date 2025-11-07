module Lich
  module DragonRealms
    # Manages the equipment for the player in the DragonRealms game.
    # This class handles the wearing, removing, and organizing of items.
    # @example
    #   manager = Lich::DragonRealms::EquipmentManager.new
    class EquipmentManager
      # Initializes a new EquipmentManager instance.
      # @param settings [Object, nil] Optional settings for the equipment manager.
      # @return [EquipmentManager]
      def initialize(settings = nil)
        items(settings)
      end

      # Retrieves the list of items managed by the EquipmentManager.
      # @param settings [Object, nil] Optional settings to initialize items.
      # @return [Array<Item>] The list of items managed.
      # @example
      #   items = manager.items
      def items(settings = nil)
        return @items if @items

        settings ||= get_settings
        @gear_sets = {}
        settings.gear_sets.each { |set_name, gear_list| @gear_sets[set_name] = gear_list.flatten.uniq }
        @sort_head = settings.sort_auto_head
        @items = settings.gear.map { |item| DRC::Item.new(name: item[:name], leather: item[:is_leather], hinders_locks: item[:hinders_lockpicking], worn: item[:is_worn], swappable: item[:swappable], tie_to: item[:tie_to], adjective: item[:adjective], bound: item[:bound], wield: item[:wield], transforms_to: item[:transforms_to], transform_verb: item[:transform_verb], transform_text: item[:transform_text], lodges: item[:lodges], ranged: item[:ranged], needs_unloading: item[:needs_unloading], skip_repair: item[:skip_repair], container: item[:container]) }
      end

      # Removes gear based on a given condition.
      # @yield [Item] A block that receives each item to determine if it should be removed.
      # @return [Array<Item>] The list of removed items.
      # @example
      #   removed = manager.remove_gear_by { |item| item.worn? }
      def remove_gear_by(&_block)
        combat_items = get_combat_items
        gear = desc_to_items(combat_items).select { |item| yield(item) }
        gear.each { |item| remove_item(item) }
        gear
      end

      # Wears a list of items.
      # @param items_list [Array<Item>] The list of items to wear.
      # @return [void]
      # @example
      #   manager.wear_items([item1, item2])
      def wear_items(items_list)
        items_list.each { |item| wear_item?(item) }

        DRC.bput('sort auto head', /^Your inventory is now arranged/) if @sort_head
      end

      # Wears an entire set of equipment.
      # @param set_name [String] The name of the gear set to wear.
      # @return [Boolean] True if all items were successfully worn, false otherwise.
      # @example
      #   success = manager.wear_equipment_set?("default")
      def wear_equipment_set?(set_name)
        return false unless set_name

        worn_items = desc_to_items(@gear_sets[set_name])
        echo("expected worn items:#{worn_items.map(&:short_name).join(',')}") if UserVars.equipmanager_debug
        unless worn_items
          echo("Could not find gear set #{set_name}")
          return false
        end

        combat_items = get_combat_items

        remove_unmatched_items(combat_items, worn_items)

        lost_items = wear_missing_items(worn_items, combat_items)
        notify_missing(lost_items)

        DRC.bput('sort auto head', /^Your inventory is now arranged/) if @sort_head

        lost_items.empty?
      end

      # Converts descriptions to item objects.
      # @param descs [Array<String>] The descriptions to convert.
      # @return [Array<Item>] The corresponding items.
      # @example
      #   items = manager.desc_to_items(descriptions)
      def desc_to_items(descs)
        descs.map { |description| item_by_desc(description) }.compact
      end

      # Finds an item by its description.
      # @param description [String] The description to match against.
      # @return [Item, nil] The matched item or nil if not found.
      # @example
      #   item = manager.item_by_desc("a shiny sword")
      def item_by_desc(description)
        items.find { |item| item.short_regex =~ description }
      end

      # Notifies the user of missing items.
      # @param lost_items [Array<Item>] The list of items that are missing.
      # @return [void]
      # @example
      #   manager.notify_missing(missing_items)
      def notify_missing(lost_items)
        return unless lost_items && !lost_items.empty?

        DRC.beep
        echo 'MISSING EQUIPMENT: Please verify these items are in a closed container and not lost:'
        echo lost_items.map(&:short_name).join(', ').to_s
        pause
        DRC.beep
      end

      # Wears items that are missing from the combat inventory.
      # @param worn_items [Array<Item>] The items that should be worn.
      # @param combat_items [Array<Item>] The current combat items.
      # @return [Array<Item>] The list of items that could not be worn.
      # @example
      #   missing = manager.wear_missing_items(worn_items, combat_items)
      def wear_missing_items(worn_items, combat_items)
        if UserVars.equipmanager_debug
          echo('wearing missing items between these two sets')
          echo(combat_items.join(',').to_s)
          echo(worn_items.map(&:short_name).join(',').to_s)
        end

        missing_items = worn_items
                        .reject { |item| combat_items.find { |c_item| item.short_regex =~ c_item } }
                        .reject { |item| [DRC.right_hand, DRC.left_hand].grep(item.short_regex).any? ? (stow_weapon(item.short_name) || true) : false }

        echo("wear missing items #{missing_items}") if !missing_items.empty? && UserVars.equipmanager_debug
        missing_items.reject { |item| wear_item?(item) }
      end

      # Removes items from combat inventory that do not match worn items.
      # @param combat_items [Array<String>] The current combat items.
      # @param worn_items [Array<Item>] The items that are currently worn.
      # @return [Array<Item>] The list of removed items.
      # @example
      #   removed = manager.remove_unmatched_items(combat_items, worn_items)
      def remove_unmatched_items(combat_items, worn_items)
        if UserVars.equipmanager_debug
          echo('removing unmatched items between these two sets')
          echo(combat_items.join(',').to_s)
          echo(worn_items.map(&:short_name).join(',').to_s)
        end
        combat_items
          .reject { |description| worn_items.find { |item| item.short_regex =~ description } }
          .map { |description| items.find { |item| item.short_regex =~ description } }
          .compact
          .each { |item| remove_item(item) }
      end

      # Retrieves the list of combat items currently worn.
      # @return [Array<String>] The list of combat items.
      # @example
      #   combat_items = manager.get_combat_items
      def get_combat_items
        snapshot = Lich::Util.issue_command("inv combat", /All of your worn combat|You aren't wearing anything like that/, /Use INVENTORY HELP for more options/, usexml: false, include_end: false)
                             .map(&:strip)
        snapshot - ["All of your worn combat equipment:", "You aren't wearing anything like that."]
      end

      # Filters the worn items based on a given list.
      # @param list [Array<String>] The list of item descriptions to filter.
      # @return [Array<Item>] The list of worn items that match the descriptions.
      # @example
      #   worn = manager.worn_items(item_descriptions)
      def worn_items(list)
        filter_gear = desc_to_items(list)
        gear = desc_to_items(get_combat_items)
        gear.select { |x| filter_gear.include?(x) }
      end

      # Removes a specific item from the inventory.
      # @param item [Item] The item to remove.
      # @return [Boolean] True if the item was successfully removed, false otherwise.
      # @example
      #   success = manager.remove_item(item)
      def remove_item(item)
        result = DRC.bput("remove my #{item.short_name}", "You .*#{item.name}", 'The leather gauntlets slide', 'Without any effort', 'you manage to loosen', "You need a free hand for that", "You'll need both hands free to do that", "then constricts tighter around your")
        waitrt?
        case result
        when /then constricts tighter around your/
          # Items that auto-repair, like exoskeletal armor,
          # may have a timer on them that prevents you removing them.
          DRC.message("The #{item.short_name} is not ready to be removed yet. Try again later.")
          return false
        when /You need a free hand for that/, /You'll need both hands free to do that/
          # We may need to empty our hands to remove the item.
          # For example, exoskeletal armor requires two hands.
          temp_left_item = DRC.left_hand
          temp_right_item = DRC.right_hand
          # Lower the items because that preserves loaded bows.
          # Stowing them in a container would require unloading.
          did_lower = [temp_left_item, temp_right_item].compact.all? { |item_in_hand| DRCI.lower_item?(item_in_hand) }
          if did_lower
            remove_item(item)
          else
            DRC.message("*** Unable to empty your hands to remove #{item.short_name} ***")
          end
          # Pick up the items in reverse order you lowered them
          # so that they end up in the correct hands again.
          DRCI.get_item_if_not_held?(temp_right_item)
          DRCI.get_item_if_not_held?(temp_left_item)
          # In case they end up in different hands, swap.
          DRC.bput('swap', /You move/, /^Will alone cannot conquer the paralysis/) if (DRC.left_hand != temp_left_item || DRC.right_hand != temp_right_item)
        else
          # If removing item transforms it (e.g. exoskeletal armor => orb) then continue with the transformed item.
          if item.transforms_to && DRCI.in_hands?(item.transforms_to)
            item = item_by_desc(item.transforms_to)
          end
          if item.tie_to
            stow_helper("tie my #{item.short_name} to my #{item.tie_to}", item.short_name, *DRCI::TIE_ITEM_SUCCESS_PATTERNS, *DRCI::TIE_ITEM_FAILURE_PATTERNS)
          elsif item.wield
            stow_helper("sheath my #{item.short_name}", item.short_name, 'Sheathing', 'You sheathe', 'You .* unload', 'You secure your', 'You slip', 'You hang', 'You .* strap', "Sheathe your .* where?")
          elsif item.container
            stow_helper("put my #{item.short_name} into my #{item.container}", item.short_name, *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, *DRCI::PUT_AWAY_ITEM_FAILURE_PATTERNS)
          elsif /more room|too long to fit/ =~ DRC.bput("stow my #{item.short_name}", 'You put', 'You should unload', 'You easily strap', 'You secure your', 'There isn\'t any more room', 'straps have all been used', 'is too long to fit')
            wear_item?(item)
          end
        end
        waitrt?
      end

      # Wears a specific item if it is available.
      # @param item [Item] The item to wear.
      # @return [Boolean] True if the item was successfully worn, false otherwise.
      # @example
      #   success = manager.wear_item?(item)
      def wear_item?(item)
        if item.nil?
          echo("failed to match an item, try turning on debugging with #{$clean_lich_char}e UserVars.equipmanager_debug = true")
          return false
        end
        if get_item?(item)
          DRCI.wear_item?(item.short_name)
          return true
        end
        return false
      end

      # This method is deprecated in favor of the one that follows the `?` predicate convention.
      # Wields a weapon into the left hand.
      # @param description [String] The description of the weapon to wield.
      # @param skill [String, nil] Optional skill to swap to.
      # @return [Boolean] True if the weapon was successfully wielded, false otherwise.
      # @example
      #   success = manager.wield_weapon_offhand("a dagger", "edged")
      def wield_weapon_offhand(description, skill = nil)
        wield_weapon_offhand?(description, skill)
      end

      # Wields weapon into your left hand.
      # Handles swapping the weapon to desired weapon skill (e.g. bastard swords, bar maces, ristes).
      # Wields a weapon into the left hand with skill handling.
      # @param description [String] The description of the weapon to wield.
      # @param skill [String, nil] Optional skill to swap to.
      # @return [Boolean] True if the weapon was successfully wielded, false otherwise.
      # @example
      #   success = manager.wield_weapon_offhand?("a dagger", "edged")
      def wield_weapon_offhand?(description, skill = nil)
        return unless description && !description.empty?

        weapon = item_by_desc(description)
        unless weapon
          DRC.message("Failed to match a weapon for #{description}:#{skill}")
          return false
        end

        if get_item?(weapon)
          swap_to_skill?(weapon.name, skill) if skill && weapon.swappable
          if DRCI.in_right_hand?(weapon)
            case DRC.bput('swap', /^You move/, /^Will alone cannot conquer the paralysis/)
            when /^You move/
              return true
            else
              return false
            end
          end
        end

        return false
      end

      # This method is deprecated in favor of the one that follows the `?` predicate convention.
      # Wields a weapon into the right hand.
      # @param description [String] The description of the weapon to wield.
      # @param skill [String, nil] Optional skill to swap to.
      # @return [Boolean] True if the weapon was successfully wielded, false otherwise.
      # @example
      #   success = manager.wield_weapon("a sword", "two-handed")
      def wield_weapon(description, skill = nil)
        wield_weapon?(description, skill)
      end

      # Wields weapon into your right hand.
      # If the skill to swap to is 'Offhand Weapon' then will swap it to your left hand.
      # Handles swapping the weapon to desired weapon skill (e.g. bastard swords, bar maces, ristes).
      # Wields a weapon into the right hand with skill handling.
      # @param description [String] The description of the weapon to wield.
      # @param skill [String, nil] Optional skill to swap to.
      # @return [Boolean] True if the weapon was successfully wielded, false otherwise.
      # @example
      #   success = manager.wield_weapon?("a sword", "two-handed")
      def wield_weapon?(description, skill = nil)
        return unless description && !description.empty?

        offhand = skill == 'Offhand Weapon'
        weapon = item_by_desc(description)
        unless weapon
          DRC.message("Failed to match a weapon for #{description}:#{skill}")
          return false
        end

        if [DRC.left_hand, DRC.right_hand].grep(weapon.short_regex).any?
          stow_weapon
        end

        if get_item?(weapon)
          swap_to_skill?(weapon.name, skill) if skill && weapon.swappable

          if offhand && DRC.right_hand
            case DRC.bput('swap', /^You move/, /^Will alone cannot conquer the paralysis/)
            when /^You move/
              return true
            else
              return false
            end
          end
        end

        return false
      end

      # Checks if an item can be obtained and handles the necessary actions.
      # @param item [Item] The item to check.
      # @return [Boolean] True if the item can be obtained, false otherwise.
      # @example
      #   can_get = manager.get_item?(item)
      def get_item?(item)
        return true if DRCI.in_hands?(item)

        if item.wield
          case DRC.bput("wield my #{item.short_name}", 'You draw', 'You deftly remove', 'You slip', 'With a flick of your wrist you stealthily unsheathe', 'Wield what', 'Your right hand is too injured', 'Your left hand is too injured')
          when 'Your right hand is too injured', 'Your left hand is too injured', 'Wield what'
            return false
          else
            return true
          end
        elsif item.transforms_to
          item = item_by_desc(item.transforms_to)
          item.worn ? get_item_helper(item, :worn) : get_item_helper(item, :stowed)
          get_item_helper(item, :transform)
        elsif (item.tie_to && get_item_helper(item, :tied)) || (item.worn && get_item_helper(item, :worn)) || (item.container && DRCI.get_item(item.short_name, item.container)) || get_item_helper(item, :stowed)
          true
        else
          echo("Could not find #{item.short_name} anywhere.")
          false
        end
      end

      # Checks if a description matches a listed item.
      # @param desc [String] The description to check.
      # @return [Item, nil] The matched item or nil if not found.
      # @example
      #   item = manager.is_listed_item?("a shiny sword")
      def is_listed_item?(desc)
        items.find { |item| item.short_regex =~ desc }
      end

      # Returns held gear to the specified gear set.
      # @param gear_set [String] The name of the gear set to return to.
      # @return [Boolean] True if all held gear was returned, false otherwise.
      # @example
      #   success = manager.return_held_gear("standard")
      def return_held_gear(gear_set = 'standard')
        return unless DRC.right_hand || DRC.left_hand

        todo = [DRC.left_hand, DRC.right_hand].compact

        worn_items = desc_to_items(@gear_sets[gear_set])

        todo.all? do |held_item|
          if (info = worn_items.find { |item| item.short_regex =~ held_item })
            unload_weapon(info.short_name) if info.needs_unloading
            stow_helper("wear my #{info.short_name}", info.short_name, 'You sling', 'You attach', 'You .* unload', 'You strap', 'You slide', 'You work your way into', 'You spin', '^You ', 'You carefully loop', 'slide effortlessly onto your', 'You slip', /^A brisk chill rushes through you/)
            true
          elsif (info = items.find { |item| item.short_regex =~ held_item })
            unload_weapon(info.short_name) if info.needs_unloading
            if info.tie_to
              stow_helper("tie my #{info.short_name} to #{info.tie_to}", info.short_name, 'You attach', 'you tie', 'You are a little too busy', 'Your wounds hinder your ability to do that')
            elsif info.wield
              stow_helper("sheath my #{info.short_name}", info.short_name, 'Sheathing', 'You sheathe', 'You .* unload', 'You secure your', 'You slip', 'You hang', 'You .* strap')
            elsif info.container
              stow_helper("put my #{info.short_name} into my #{info.container}", info.short_name, *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, *DRCI::PUT_AWAY_ITEM_FAILURE_PATTERNS)
            else
              stow_helper("stow my #{info.short_name}", info.short_name, 'You put', 'You should unload', 'You easily strap', 'You secure your')
            end
            true
          else
            false
          end
        end
      end

      # Empties the hands by returning held gear or stowing hands.
      # @return [void]
      # @example
      #   manager.empty_hands
      def empty_hands
        return_held_gear || DRCI.stow_hands
      end

      # Retrieves verb data for a specific item.
      # @param item [Item] The item to retrieve verb data for.
      # @return [Hash] A hash containing verb data for the item.
      # @example
      #   data = manager.verb_data(item)
      def verb_data(item)
        {
          worn: {
            verb: 'remove',
            matches: [/^You .*#{item.short_regex}/, /^You (get|sling|pull|work|loosen|slide|remove|yank|unbuckle).*#{item.name}/, 'you tug', 'Remove what', "You aren't wearing that", 'slide themselves off of your', 'you manage to loosen', /^A brisk chill leaves you as you/],
            failures: [/^You (get|sling|pull|work|slide|remove|yank|unbuckle) $/],
            failure_recovery: proc { |noun| DRC.bput("wear my #{noun}", '^You ') },
            exhausted: ['Remove what', "You aren't wearing that"]
          },
          tied: {
            verb: 'untie',
            matches: [/^You .*#{item.short_regex}/, "^You remove.*#{item.name}", /^.*you untie your .*#{item.short_regex} from it./, '^What were you referring', '^Untie what', '^You are a little too busy', '^You are a bit too busy'],
            failures: ['You remove', /^You are a little too busy/, /^You are a bit too busy/],
            failure_recovery: proc { |_noun, item_to_recover, *matches|
                                case matches
                                when ['You are a little too busy']
                                  DRC.retreat
                                  get_item?(item_to_recover)
                                when ['You are a bit too busy']
                                  DRC.stop_playing
                                  get_item?(item_to_recover)
                                else
                                  stow_weapon
                                end
                              },
            exhausted: ['What were you referring', 'Untie what']
          },
          stowed: {
            verb: 'get',
            matches: [/^You .*#{item.short_regex}/, "^You .*#{item.name}", '^The.* slides easily out', '^What were you referring', 'But that is already', 'You are already'],
            failures: ['You get', /But that is already/],
            failure_recovery: proc { |noun| DRC.bput("stow my #{noun}", 'You put', 'But that is already in') },
            exhausted: ['What were you referring']
          },
          transform: {
            verb: item.transform_verb,
            matches: [item.transform_text],
            failures: ["You'll need a free hand to do that!", "You don't seem to be holding"],
            failure_recovery: proc do |noun|
                                fput('stow left') if DRC.left_hand && DRC.left_hand !~ /#{noun}/i
                                fput('stow right') if DRC.right_hand && DRC.right_hand !~ /#{noun}/i
                                item.worn ? DRC.bput("remove my #{noun}", '^You') : DRC.bput("get my #{noun}", '^You')
                                DRC.bput("#{item.transform_verb} my #{item.short_name}", verb_data(item)[:matches])
                              end,
            exhausted: ['What were you referring']
          }
        }
      end

      # Helper method to get an item based on its type.
      # @param item [Item] The item to get.
      # @param type [Symbol] The type of action to perform (e.g., :worn, :stowed).
      # @return [Boolean] True if the item was successfully obtained, false otherwise.
      # @example
      #   success = manager.get_item_helper(item, :worn)
      def get_item_helper(item, type)
        return false unless item

        data = verb_data(item)[type]
        snapshot = [DRC.left_hand, DRC.right_hand]
        waitrt?
        response = DRC.bput("#{data[:verb]} my #{item.short_name}", *data[:matches])
        waitrt?
        case response
        when 'You are already holding'
          return true
        when *data[:exhausted]
          return false
        when *data[:failures]
          data[:failure_recovery].call(item.name, item, response)
        else
          pause 0.05 while snapshot == [DRC.left_hand, DRC.right_hand]
          return true
        end
      end

      # Turns a weapon so that it can be used as a different weapon.
      # Examples include Damaris weapons.
      # Turns a weapon to be used as a different weapon.
      # @param old_noun [String] The current name of the weapon.
      # @param new_noun [String] The new name of the weapon.
      # @return [Boolean] True if the weapon was successfully turned, false otherwise.
      # @example
      #   success = manager.turn_to_weapon?("a sword", "a dagger")
      def turn_to_weapon?(old_noun, new_noun)
        return true if old_noun == new_noun

        result = DRC.bput("turn my #{old_noun} to #{new_noun}", /^Turn what?/i, /^Which weapon did you want to pull out/i, /^Your .*\b#{old_noun}.* shifts .*/i)
        waitrt? # turning may incur roundtime
        case result
        when /^Your .*\b#{old_noun}.* shifts .* before resolving itself into .*\b#{new_noun}/i
          true
        else
          false
        end
      end

      # Swaps a weapon so that it can be used for a different skill.
      # Examples include bastard swords, bar maces, and ristes.
      # Swaps a weapon to be used for a different skill.
      # @param noun [String] The name of the weapon to swap.
      # @param skill [String] The skill to swap to.
      # @return [Boolean] True if the weapon was successfully swapped, false otherwise.
      # @example
      #   success = manager.swap_to_skill?("a sword", "two-handed")
      def swap_to_skill?(noun, skill)
        if noun =~ /\bfan\b/i
          command = skill =~ /edged/i ? 'open' : 'close'
          DRC.bput("#{command} my fan", 'you snap', 'already')
          return true
        end
        proper_skill = case skill
                       when /^he$|heavy edge|large edge|one-handed/i
                         'heavy edged'
                       when /^2he$|^the$|twohanded edge|two-handed edge/i
                         'two-handed edged'
                       when /^hb$|heavy blunt|large blunt/i
                         'heavy blunt'
                       when /^2hb$|^thb$|twohanded blunt|two-handed blunt/i
                         'two-handed blunt'
                       when /^se$|small edged|light edge|medium edge/i
                         '(light edged|medium edged)'
                       when /^sb$|small blunt|light blunt|medium blunt/i
                         '(light blunt|medium blunt)'
                       when /^lt$|light thrown/i
                         'light thrown'
                       when /^ht$|heavy thrown/i
                         'heavy thrown'
                       when /stave/i
                         '(short|quarter) staff'
                       when /polearms/i
                         '(halberd|pike)'
                       when /^ow$|offhand weapon/i
                         return true # just use weapon in your left hand
                       else
                         DRC.message("Unsupported weapon swap: #{noun} to #{skill}. Please report this to https://github.com/elanthia-online/dr-scripts/issues")
                         return false
                       end
        # All possible weapon skills to swap into.
        weapon_skills = [
          'light edged',
          'medium edged',
          'heavy edged',
          'two-handed edged',
          'light blunt',
          'medium blunt',
          'heavy blunt',
          'two-handed blunt',
          'light thrown',
          'heavy thrown',
          'short staff',
          'quarter staff',
          'halberd',
          'pike'
        ]
        failure_matches = [
          /You have nothing to swap/,
          /Your (left|right) hand is too injured/,
          /Will alone cannot conquer the paralysis that has wracked your body/,
          /^You move a .* to your (left|right) hand/
        ]
        # The spaces in the regex are deliberate
        skill_match = / #{proper_skill} /i
        swapped_count = 0
        loop do
          pause 0.25
          # Avoid infinite loop where weapon can't swap to desired skill.
          return false if swapped_count > weapon_skills.length

          # Try to swap weapon to desired skill.
          case DRC.bput("swap my #{noun}", skill_match, /\b#{noun}\b.*(#{weapon_skills.join('|')})/, "You must have two free hands", *failure_matches)
          when /You must have two free hands/
            fput('stow left') if DRC.left_hand && DRC.left_hand !~ /#{noun}/i
            fput('stow right') if DRC.right_hand && DRC.right_hand !~ /#{noun}/i
            next
          when *failure_matches
            return false
          when skill_match
            return true
          end
          swapped_count = swapped_count + 1
        end
      end

      # Unloads a weapon from the player's hands.
      # @param name [String] The name of the weapon to unload.
      # @return [void]
      # @example
      #   manager.unload_weapon("a bow")
      def unload_weapon(name)
        # Phrases to match:
        #   (hidden) You remain concealed by your surroundings, convinced that your unloading of the <weapon> went unobserved.
        #   (hidden) You unload your <weapon> while blended in with your surroundings, but cannot shake the feeling that you drew attention to yourself.
        #   (one hand empty) You unload the <weapon>.
        #   (hands full) Your <ammo> falls from your <weapon> to your feet.
        case DRC.bput("unload my #{name}", /^You unload/, /^Your .* fall.*to your feet\.$/, 'As you release the string', /^You .* unloading/, 'But your .* isn\'t loaded', 'You can\'t unload such a weapon', 'You don\'t have a ranged weapon to unload', 'You must be holding the weapon to do that')
        when /^(?:Your .*?\b(?<ammo>[\w]+)\b fall.* from your .* to your feet\.)$/
          # Ammo fell to ground because hands are full.
          # Lower weapon, stow ammo, then pick it back up.
          ammo = Regexp.last_match[:ammo]
          DRC.bput("lower ground left", "You lower") if DRCI.in_left_hand?(name)
          DRC.bput("lower ground right", "You lower") if DRCI.in_right_hand?(name)
          DRCI.put_away_item?(ammo)
          DRC.bput("get my #{name}", "You get", "You pick")
        when /^(You unload|You .* unloading)/
          # Ammo is in hand, stow whichever hand isn't holding the weapon.
          DRC.bput("stow left", "You put") unless DRCI.in_left_hand?(name)
          DRC.bput("stow right", "You put") unless DRCI.in_right_hand?(name)
        end
        waitrt?
      end

      # Stows a weapon, optionally specifying which weapon to stow.
      # @param description [String, nil] The description of the weapon to stow.
      # @return [void]
      # @example
      #   manager.stow_weapon("a sword")
      def stow_weapon(description = nil)
        unless description
          return unless DRC.right_hand || DRC.left_hand

          stow_weapon(DRC.right_hand) if DRC.right_hand
          stow_weapon(DRC.left_hand)  if DRC.left_hand
          return
        end
        weapon = item_by_desc(description)
        return unless weapon

        # Is this a weapon that needs to be unloaded before it is put away?
        # This is an optimization attempt so that the script
        # isn't trying to unload every weapon that gets put away.
        # Would be silly to try "unload my scimitar" wouldn't it? :grins:
        unload_weapon(weapon.short_name) if weapon.needs_unloading
        if weapon.wield
          stow_helper("sheath my #{weapon.short_name}", weapon.short_name, 'Sheathing', 'You sheathe', 'You .* unload', 'close the fan', 'You secure your', 'You slip', 'You hang', 'You strap', "You don't seem to be able to move", 'You easily strap', 'is too small to hold that', 'is too wide to fit', 'With a flick of your wrist you stealthily sheathe', '^The .* slides easily', "There's no room", "Sheathe your .* where?", 'Your (left|right) hand is too injured')
        elsif weapon.worn
          stow_helper("wear my #{weapon.short_name}", weapon.short_name, 'You sling', 'You attach', 'You .* unload', 'You slide', 'You place', 'close the fan', 'You hang', 'You spin', 'You strap', 'You put', 'You carefully loop', "You don't seem to be able to move", "You are already wearing", "You work your way into", 'slide effortlessly onto your', "You can't wear")
        elsif !weapon.tie_to.nil?
          stow_helper("tie my #{weapon.short_name} to my #{weapon.tie_to}", weapon.short_name, 'You attach', 'close the fan', 'you tie', 'You are a little too busy', "You don't seem to be able to move", 'Your wounds hinder your ability to do that', 'You must be holding')
        elsif weapon.transforms_to
          stow_helper("#{weapon.transform_verb} my #{weapon.short_name}", weapon.short_name, weapon.transform_text)
          stow_weapon(weapon.transforms_to)
        elsif weapon.container
          stow_helper("put my #{weapon.short_name} in my #{weapon.container}", weapon.short_name, "You put .*#{weapon.name}", *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, *DRCI::PUT_AWAY_ITEM_FAILURE_PATTERNS)
        else
          stow_helper("stow my #{weapon.short_name}", weapon.short_name, "You put .*#{weapon.name}", 'You .* unload', 'close the fan', 'You easily strap', "You don't seem to be able to move", 'You secure', 'is too small to hold that', 'is too wide to fit', 'You hang', '^The .* slides easily', "There's no room")
        end
      end

      # Helper method to perform stowing actions with error handling.
      # @param action [String] The action to perform for stowing.
      # @param weapon_name [String] The name of the weapon to stow.
      # @param accept_strings [Array<String>] The strings to match against for success.
      # @return [void]
      # @example
      #   manager.stow_helper("stow my sword", "sword", ["You put", "You should unload"])
      def stow_helper(action, weapon_name, *accept_strings)
        case DRC.bput(action, accept_strings)
        when /unload/
          unload_weapon(weapon_name)
          stow_helper(action, weapon_name, accept_strings)
        when /close the fan/
          fput("close my #{weapon_name}")
          stow_helper(action, weapon_name, accept_strings)
        when /You are a little too busy/
          DRC.retreat
          stow_helper(action, weapon_name, accept_strings)
        when /You don't seem to be able to move/
          pause 1
          stow_helper(action, weapon_name, accept_strings)
        when /is too small to hold that/
          fput("swap my #{weapon_name}")
          stow_helper(action, weapon_name, accept_strings)
        when /Your wounds hinder your ability to do that/, /Sheathe your .* where/
          stow_helper("stow my #{weapon_name}", weapon_name, 'You put', 'You should unload', 'You easily strap', 'You secure your')
        end
      end
    end
  end
end
