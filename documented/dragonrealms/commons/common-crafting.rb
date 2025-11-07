# Lich module containing various crafting functionalities
# @example
#   include Lich::DragonRealms::DRCC
module Lich
  module DragonRealms
    module DRCC
      module_function

      # Checks if the crucible is empty.
      # @return [Boolean] true if the crucible is empty, false otherwise
      # @example
      #   if empty_crucible?
      #     puts "The crucible is empty."
      #   end
      def empty_crucible?
        case result = DRC.bput('look in cruc',
                               '^I could not find',
                               '^There is nothing in there',
                               '^In the .* crucible you see (.*)\.')
        when /There is nothing in there/i
          true
        when /I could not find/
          false
        when /crucible you see some molten/
          fput('tilt crucible')
          fput('tilt crucible')
          return DRCC.empty_crucible?
        when /crucible you see/
          clutter = result
                    .match(/In the .* you see (?:some|an|a) (?<items>.*)\./)[:items]
                    .split(/(?:,|and) (?:some|an|a)/)
                    .map(&:strip)
          clutter.each { |junk|
            junk = DRC.get_noun(junk)
            DRCI.get_item_unsafe(junk, 'crucible')
            DRCI.dispose_trash(junk)
          }
          return DRCC.empty_crucible?
        else
          false
        end
      end

      # Finds an empty crucible in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @return [void]
      # @example
      #   find_empty_crucible("Crossing")
      def find_empty_crucible(hometown)
        return if DRC.bput('tap crucible', 'I could not', /You tap.*crucible/) =~ /You tap.*crucible/ && (DRRoom.pcs - DRRoom.group_members).empty? && empty_crucible?

        crucibles = get_data('crafting')['blacksmithing'][hometown]['crucibles']
        idle_room = get_data('crafting')['blacksmithing'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(crucibles, idle_room, proc { (DRRoom.pcs - DRRoom.group_members).empty? && empty_crucible? })
        DRCC.clean_anvil?
      end

      # Checks if the anvil is clean.
      # @return [Boolean] true if the anvil is clean, false otherwise
      # @example
      #   if clean_anvil?
      #     puts "The anvil is clean."
      #   end
      def clean_anvil?
        case result = DRC.bput('look on anvil', '^I could not find', 'surface looks clean and ready', "anvil you see (.*)\.")
        when /surface looks clean and ready/i
          true
        when /I could not find/
          false
        when /anvil you see/
          /anvil you see (.*)\./ =~ result
          clutter = Regexp.last_match(1).split.last
          case DRC.bput('clean anvil', 'You drag the', 'remove them yourself')
          when /drag/
            fput('clean anvil')
            pause
            waitrt?
          else
            case DRC.bput("get #{clutter} from anvil", 'You get', 'is not yours')
            when 'is not yours'
              fput('clean anvil')
              fput('clean anvil')
            when 'You get'
              DRC.bput("put #{clutter} in bucket", 'You drop')
            else
              return false
            end
          end
          true
        else
          false
        end
      end

      # Finds a wheel in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @return [void]
      # @example
      #   find_wheel("Crossing")
      def find_wheel(hometown)
        wheels = get_data('crafting')['tailoring'][hometown]['spinning-rooms']
        idle_room = get_data('crafting')['tailoring'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(wheels, idle_room)
      end

      # Finds an anvil in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @return [void]
      # @example
      #   find_anvil("Crossing")
      def find_anvil(hometown)
        return if DRC.bput('tap anvil', 'I could not', /You tap.*anvil/) =~ /You tap.*anvil/ && (DRRoom.pcs - DRRoom.group_members).empty? && clean_anvil?

        anvils = get_data('crafting')['blacksmithing'][hometown]['anvils']
        idle_room = get_data('crafting')['blacksmithing'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(anvils, idle_room, proc { (DRRoom.pcs - DRRoom.group_members).empty? && clean_anvil? })
        DRCC.empty_crucible?
      end

      # Finds a grindstone in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @return [void]
      # @example
      #   find_grindstone("Crossing")
      def find_grindstone(hometown)
        return unless DRC.bput('tap grindstone', 'I could not', 'You tap.*grindstone') == 'I could not'

        grindstones = get_data('crafting')['blacksmithing'][hometown]['grindstones']
        idle_room = get_data('crafting')['blacksmithing'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(grindstones, idle_room)
      end

      # Finds a sewing room in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @param override [String, nil] Optional override location.
      # @return [void]
      # @example
      #   find_sewing_room("Crossing")
      def find_sewing_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          sewingrooms = get_data('crafting')['tailoring'][hometown]['sewing-rooms']
          idle_room = get_data('crafting')['tailoring'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(sewingrooms, idle_room)
        end
      end

      # Finds a loom room in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @param override [String, nil] Optional override location.
      # @return [void]
      # @example
      #   find_loom_room("Crossing")
      def find_loom_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          loom_rooms = get_data('crafting')['tailoring'][hometown]['loom-rooms']
          idle_room = get_data('crafting')['tailoring'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(loom_rooms, idle_room)
        end
      end

      # Finds a shaping room in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @param override [String, nil] Optional override location.
      # @return [void]
      # @example
      #   find_shaping_room("Crossing")
      def find_shaping_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          shapingrooms = get_data('crafting')['shaping'][hometown]['shaping-rooms']
          idle_room = get_data('crafting')['shaping'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(shapingrooms, idle_room)
        end
      end

      # Finds a press grinder room in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @return [void]
      # @example
      #   find_press_grinder_room("Crossing")
      def find_press_grinder_room(hometown)
        return unless DRC.bput('tap grinder', 'I could not', 'You tap.*grinder') == 'I could not'

        pressgrinderrooms = get_data('crafting')['remedies'][hometown]['press-grinder-rooms']
        DRCT.walk_to(pressgrinderrooms[0])
      end

      # Finds an enchanting room in the specified hometown.
      # @param hometown [String] The name of the hometown to search in.
      # @param override [String, nil] Optional override location.
      # @return [void]
      # @example
      #   find_enchanting_room("Crossing")
      def find_enchanting_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          enchanting_rooms = get_data('crafting')['artificing'][hometown]['brazier-rooms']
          idle_room = get_data('crafting')['artificing'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(enchanting_rooms, idle_room, proc { (DRRoom.pcs - DRRoom.group_members).empty? && clean_brazier? })
        end
      end

      # Looks up a recipe by item name.
      # @param recipes [Array<Hash>] The list of recipes to search through.
      # @param item_name [String] The name of the item to look for.
      # @return [Hash, nil] The matching recipe or nil if not found.
      # @example
      #   recipe = recipe_lookup(recipes, "metal pike")
      def recipe_lookup(recipes, item_name)
        match_names = recipes.map { |x| x['name'] }.select { |x| x =~ /#{item_name}/i }
        case match_names.length
        when 0
          echo("No recipe in base-recipes.yaml matches #{item_name}")
          nil
        when 1
          recipes.find { |x| x['name'] =~ /#{item_name}/i }
        else
          exact_matches = recipes.map { |x| x['name'] }.select { |x| x == item_name }

          if exact_matches.length == 1
            return recipes.find { |x| x['name'] == item_name }
          end

          DRC.message("Using the full name of the item you wish to craft will avoid this in the future (e.g. 'a metal pike' vs 'metal pike')")
          echo("Please select desired recipe #{$clean_lich_char}send #")
          match_names.each_with_index { |x, i| respond "    #{i + 1}: #{x}" }
          line = get until line.strip =~ /^([0-9]+)$/
          item_name = match_names[Regexp.last_match(1).to_i - 1]
          recipes.find { |x| x['name'] =~ /#{item_name}/i }
        end
      end

      # Finds a recipe in a specified chapter of a book.
      # @param chapter [Integer] The chapter number to turn to.
      # @param match_string [String] The string to match in the recipe.
      # @param book [String] The name of the book to read from.
      # @return [Integer, nil] The page number of the recipe or nil if not found.
      # @example
      #   page = find_recipe(1, "metal pike")
      def find_recipe(chapter, match_string, book = 'book')
        case DRC.bput("turn my #{book} to chapter #{chapter}", 'You turn', 'You are too distracted to be doing that right now', 'The .* is already turned')
        when 'You are too distracted to be doing that right now'
          echo '***CANNOT TURN BOOK, ASSUMING I AM ENGAGED IN COMBAT***'
          fput('look')
          fput('exit')
        end

        recipe = DRC.bput("read my #{book}", "Page \\d+:\\s(?:some|a|an)?\\s*#{match_string}").split('Page').find { |x| x =~ /#{match_string}/i }
        recipe =~ /(\d+):/
        Regexp.last_match(1)
      end

      # Finds a recipe in a specified chapter and discipline of a book.
      # @param chapter [Integer] The chapter number to turn to.
      # @param match_string [String] The string to match in the recipe.
      # @param book [String] The name of the book to read from.
      # @param discipline [String, nil] Optional discipline to turn to.
      # @return [Integer, nil] The page number of the recipe or nil if not found.
      # @example
      #   page = find_recipe2(1, "metal pike", "book", "blacksmithing")
      def find_recipe2(chapter, match_string, book = 'book', discipline = nil)
        DRC.bput("turn my #{book} to discipline #{discipline}", /^You turn the #{book} to the section on/) unless discipline.nil?
        case DRC.bput("turn my #{book} to chapter #{chapter}", /^You turn your #{book} to chapter/, /^The #{book} is already turned to chapter/, /^You are too distracted to be doing that right now./)
        when /^You are too distracted to be doing that right now./
          echo '***CANNOT TURN BOOK, ASSUMING I AM ENGAGED IN COMBAT***'
          fput('look')
          fput('exit')
        end

        recipe = DRC.bput("read my #{book}", "Page \\d+:\\s(?:some|a|an)?\\s*#{match_string}").split('Page').find { |x| x =~ /#{match_string}/i }
        recipe =~ /(\d+):/
        page = Regexp.last_match(1)
        DRC.bput("turn my #{book} to page #{page}", /^You turn your #{book} to page/, /^You are already on page/)
        DRC.bput("study my #{book}", /^Roundtime/)
      end

      # Retrieves a crafting item from the specified bag or belt.
      # @param name [String] The name of the item to retrieve.
      # @param bag [String] The name of the bag to search in.
      # @param bag_items [Array<String>] The list of items in the bag.
      # @param belt [Hash] The belt containing items.
      # @param skip_exit [Boolean] Whether to skip exit on failure.
      # @return [void]
      # @example
      #   get_crafting_item("metal pike", "backpack", bag_items, belt)
      def get_crafting_item(name, bag, bag_items, belt, skip_exit = false)
        waitrt?
        if belt && belt['items'].find { |item| /\b#{name}/i =~ item || /\b#{item}/i =~ name }
          case DRC.bput("untie my #{name} from my #{belt['name']}", /^You (remove|untie)/, /^You are already/, /^Untie what/, /^Your wounds hinder your ability to do that/)
          when /You (remove|untie)/, /You are already/
            return
          when /Your wounds hinder your ability to do that/
            craft_room = Room.current.id
            DRC.wait_for_script_to_complete('safe-room', ['force'])
            DRCT.walk_to(craft_room)
            return get_crafting_item(name, bag, bag_items, belt)
          end
        end
        command = "get my #{name}"
        command += " from my #{bag}" if bag_items && bag_items.include?(name)
        case DRC.bput(command, /^You get/, /^You are already/, /^What do you/, /^What were you/, /^You pick up/, /can't quite lift it/, /^You should untie/)
        when 'What do you', 'What were you'
          pause 2
          return if DRCI.in_hands?(name)

          DRC.beep
          echo("You seem to be missing: #{name}")
          exit unless skip_exit
        when "can't quite lift it"
          get_crafting_item(name, bag, bag_items, belt)
        when 'You should untie'
          case DRC.bput("untie my #{name}", /^You (remove|untie)/, /^Untie what/, /^Your wounds hinder your ability to do that/)
          when /You (remove|untie)/
            return
          when /Your wounds hinder your ability to do that/
            craft_room = Room.current.id
            DRC.wait_for_script_to_complete('safe-room', ['force'])
            DRCT.walk_to(craft_room)
            return get_crafting_item(name, bag, bag_items, belt)
          end
        end
      end

      # Stows a crafting item into the specified bag or belt.
      # @param name [String] The name of the item to stow.
      # @param bag [String] The name of the bag to stow in.
      # @param belt [Hash] The belt containing items.
      # @return [Boolean] true if stowed successfully, false otherwise.
      # @example
      #   stow_crafting_item("metal pike", "backpack", belt)
      def stow_crafting_item(name, bag, belt)
        return unless name

        waitrt?
        if belt && belt['items'].find { |item| /\b#{name}/i =~ item || /\b#{item}/i =~ name }
          case DRC.bput("tie my #{name} to my #{belt['name']}", 'you attach', 'Your wounds hinder')
          when 'Your wounds hinder'
            craft_room = Room.current.id
            DRC.wait_for_script_to_complete('safe-room', ['force'])
            DRCT.walk_to(craft_room)
            return stow_crafting_item(name, bag, belt)
          end
        else
          case DRC.bput("put my #{name} in my #{bag}", 'You tuck', 'You put your', 'What were you referring to', 'is too \w+ to fit', 'Weirdly, you can\'t manage', 'There\'s no room', 'You can\'t put that there', 'You combine')
          when /is too \w+ to fit/, 'Weirdly, you can\'t manage', 'There\'s no room'
            fput("stow my #{name}")
          when 'You can\'t put that there'
            fput("put my #{name} in my other #{bag}")
            return false
          end
        end
        true
      end

      # Calculates the crafting cost for a given recipe.
      # @param recipe [Hash] The recipe details including name and volume.
      # @param hometown [String] The name of the hometown.
      # @param parts [Array<String>] The list of parts required.
      # @param quantity [Integer] The number of items to craft.
      # @param material [Hash] The material details including stock information.
      # @return [Integer] The total cost of crafting.
      # @example
      #   cost = crafting_cost(recipe, "Crossing", parts, 2, material)
      def crafting_cost(recipe, hometown, parts, quantity, material)
        # To use this method, you'll need to pass:
        # recipe => This is a hash drawn directly from base-recipes eg {name: 'a metal ring cap', noun: 'cap', volume: 8, type: 'armorsmithing',etc}
        #     This is fetched via get_data('recipes').crafting_recipes('name')[<name of recipe>]
        # hometown => Just a string eg "Crossing"
        # parts => This is an array containing(if any) a list of parts required. Where base-recipes doesn't do this, you will need to format this.
        # quantity => an integer representing how many of each finished craft you intend to make. You can call this once per item, or once for all items.
        # material => This needs to be a hash drawn directly from base-crafting eg {stock-volume: 5, stock-number: 11, stock-name: 'bronze', stock-value: 562}
        #     This is fetched via get_data('crafting')['stock'][<name of material>]
        #     nil or false if not using stock materials

        currency = DRCM.town_currency(hometown)
        data = get_data('crafting')['stock'] # fetch parts data

        if material && ["alabaster", "granite", "marble"].any? { |x| material['stock-name'] == x } # stone isn't stackable, so just calculate stock*quantity
          total += material['stock-value'] * quantity
        elsif material # neither alchemy nor artificing have ONE stock material, they take various materials and combine them, so those are handled by parts below
          stock_to_order = ((recipe['volume'] / material['stock-volume'].to_f) * quantity).ceil
          total += (stock_to_order * material['stock-value'])
        end

        if parts
          parts_cannot_purchase = ['sufil', 'blue flower', 'muljin', 'belradi', 'dioica', 'hulnik', 'aloe', 'eghmok', 'lujeakave', 'yelith', 'cebi', 'blocil', 'hulij', 'nuloe', 'hisan', 'gem', 'pebble', 'ring', 'gwethdesuan', 'brazier', 'burin', 'any', 'ingot', 'mechanism']
          parts.reject! { |part| parts_cannot_purchase.include?(part) } # excludes things you cannot purchase, so won't error if you've got these.
          parts.each { |part| total += data[part]['stock-value'] * quantity } # adds the cost of each purchasable part to the total
        end

        total += 1000 # added to account for consumables, water, coal, etc

        if currency == 'kronars'
          return total
        elsif currency == 'lirums'
          return (total * 0.800).ceil
        elsif currency == 'dokoras'
          return (total * 0.7216).ceil
        end
      end

      # Repairs the user's own tools if eligible.
      # @param info [Hash] Information about the tools and repair locations.
      # @param tools [Array<String>] The list of tools to repair.
      # @param bag [String] The name of the bag containing tools.
      # @param bag_items [Array<String>] The list of items in the bag.
      # @param belt [Hash] The belt containing items.
      # @return [void]
      # @example
      #   repair_own_tools(info, tools, "backpack", bag_items, belt)
      def repair_own_tools(info, tools, bag, bag_items, belt)
        UserVars.immune_list ||= {} # declaring a hash unless hash already
        tools = tools.to_a # Convert single tool string to array
        UserVars.immune_list.reject! { |_k, v| v < Time.now } # removing anything from the immune list that has an expired timer
        tools.reject! { |x| UserVars.immune_list[x] } # removing tools from the list of eligible repairs if they're still on the immune list
        return unless tools.size > 0 # skips the whole method if no tools are eligible for repairs

        DRCC.check_consumables('oil', info['finisher-room'], info['finisher-number'], bag, bag_items, belt, tools.size) # checks intelligently for enough oil uses to repair the number of tools eligible for repair
        DRCC.check_consumables('wire brush', info['finisher-room'], 10, bag, bag_items, belt, tools.size) # checks intelligently for enough brush uses to repair the number of tools eligible for repair
        repair_tool = ['wire brush', 'oil']
        tools.each do |tool_name| # begins repair cycle for each tool
          DRCC.get_crafting_item(tool_name, bag, bag_items, belt, true) # attempts to fetch the next tool, with the option (true) to continue if fetch fails
          next unless DRC.right_hand # if we don't get the next tool for whatever reason, we move on to the next tool.

          repair_tool.each do |x| # iterates once for each: wire brush, oil
            DRCC.get_crafting_item(x, bag, bag_items, belt)
            command = x == 'wire brush' ? "rub my #{tool_name} with my wire brush" : "pour my oil on my #{tool_name}" # changes the command based on the tool, instead of a second case statement, since it's just one of each

            case DRC.bput(command, 'Roundtime', 'not damaged enough',
                          'You cannot do that while engaged!', 'cannot figure out how', 'Pour what')
            when 'Roundtime' # successful partial repair (one brush or one oil)
              DRCC.stow_crafting_item(x, bag, belt)
              next # move to oil, or move out of loop
            when 'not damaged enough' # doesn't require repair, leaving loop for the next tool
              DRCC.stow_crafting_item(x, bag, belt)
              break # leave brush/oil loop and choose next tool
            when 'Pour what'
              DRCC.check_consumables('oil', info['finisher-room'], info['finisher-number'], bag, bag_items, belt) # somehow ran out of oil, fetching more
              DRCC.get_crafting_item(x, bag, bag_items, belt)
              DRC.bput("pour my oil on my #{tool_name}", 'Roundtime')
              DRCC.stow_crafting_item(x, bag, belt)
              next # oil done, next tool
            when 'You cannot do that while engaged!'
              DRC.message("Cannot repair in combat")
              DRCC.stow_crafting_item(tool_name, bag, belt)
              DRCC.stow_crafting_item(x, bag, belt)
              break
            when 'cannot figure out how'
              DRC.message("Something has gone wrong, exiting repair")
              DRCC.stow_crafting_item(tool_name, bag, belt)
              DRCC.stow_crafting_item(x, bag, belt)
              break
            end
          end
          UserVars.immune_list.store(tool_name, Time.now + 7000) if Flags['proper-repair'] # if our flag picks up a Proper Forging Tool Care successful repair, we add that tool and a time of now plus 7000 seconds (just shy of 2 hours) to the list of immune tools
          Flags.reset('proper-repair')
          DRCC.stow_crafting_item(tool_name, bag, belt)
        end
        return
      end

      # Checks if the specified consumable is available and retrieves it if necessary.
      # @param name [String] The name of the consumable to check.
      # @param room [String] The room to check in.
      # @param number [Integer] The number of consumables needed.
      # @param bag [String] The name of the bag containing consumables.
      # @param bag_items [Array<String>] The list of items in the bag.
      # @param belt [Hash] The belt containing items.
      # @param count [Integer] The minimum count required.
      # @return [void]
      # @example
      #   check_consumables("oil", "finisher-room", 10, "backpack", bag_items, belt)
      def check_consumables(name, room, number, bag, bag_items, belt, count = 3)
        current = Room.current.id
        case DRC.bput("get my #{name} from my #{bag}", 'You get', 'What were')
        when 'You get'
          /(\d+)/ =~ DRC.bput("count my #{name}", 'The .* has (\d+) uses remaining', 'You count out (\d+) yards of material there')
          if Regexp.last_match(1).to_i < count
            DRCT.dispose(name)
            DRCC.check_consumables(name, room, number, bag, bag_items, belt, count)
          end
          DRCC.stow_crafting_item(name, bag, belt)
        else
          DRCT.order_item(room, number)
          DRCC.stow_crafting_item(name, bag, belt)
        end
        DRCT.walk_to(current)
      end

      # Adjusts the tongs based on the specified usage.
      # @param usage [String] The usage type, either 'shovel' or 'tongs'.
      # @param bag [String] The name of the bag containing tongs.
      # @param bag_items [Array<String>] The list of items in the bag.
      # @param belt [Hash] The belt containing items.
      # @param adjustable_tongs [Boolean] Whether the tongs are adjustable.
      # @return [Boolean] true if adjusted successfully, false otherwise.
      # @example
      #   adjusted = get_adjust_tongs?('shovel', "backpack", bag_items, belt)
      def get_adjust_tongs?(usage, bag, bag_items, belt, adjustable_tongs = false)
        case usage
        when 'shovel' # looking for a shovel
          if @tongs_status == 'shovel' # tongs already a shovel
            DRCC.get_crafting_item('tongs', bag, bag_items, belt) unless DRCI.in_hands?('tongs') # get unless already holding
            return true # tongs previously set to shovel, in hands, adjusted to shovel.
          elsif !adjustable_tongs # determines state of tongs, works either nil or tongs
            return false # non-adjustable
          else
            DRCC.get_crafting_item('tongs', bag, bag_items, belt) unless DRCI.in_hands?('tongs') # get unless already holding

            case DRC.bput("adjust my tongs", 'You lock the tongs', 'With a yank you fold the shovel', 'You cannot adjust', 'You have no idea how')
            when 'You cannot adjust', 'You have no idea how' # holding tongs, not adjustable, settings are wrong.
              DRC.message('Tongs are not adjustable. Please change yaml to reflect adjustable_tongs: false')
              DRCC.stow_crafting_item('tongs', bag, belt) # stows to make room for shovel
              return false
            when 'With a yank you fold the shovel' # now tongs, adjust success but in wrong configuration
              DRC.bput("adjust my tongs", 'You lock the tongs') # now shovel, ready to work
              @tongs_status = 'shovel' # correcting instance variable
              return true # tongs as shovel
            when 'You lock the tongs' # now shovel, adjust success
              @tongs_status = 'shovel' # setting instance variable
              return true # tongs as shovel
            end
          end

          # at this point, we either have tongs-in-shovel and a return of true, or tongs stowed(if in left hand) and a return of false

        when 'tongs' # looking for tongs
          DRCC.get_crafting_item('tongs', bag, bag_items, belt) unless DRCI.in_hands?('tongs') # get unless already holding. Here we are always getting tongs, never stowing tongs.
          if @tongs_status == 'tongs' # tongs as tongs already
            return true # tongs previously set to tongs, in hands, adjusted to tongs. this will not catch unscripted adjustments to tongs.
          elsif !adjustable_tongs # determines state of tongs, works either nil or shovel
            return false # have tongs, as tongs, but not adjustable.
          else

            case DRC.bput("adjust my tongs", 'You lock the tongs', 'With a yank you fold the shovel', 'You cannot adjust', 'You have no idea how')
            when 'You cannot adjust', 'You have no idea how' # holding tongs, not adjustable, settings are wrong.
              DRC.message('Tongs are not adjustable. Please change yaml to reflect adjustable_tongs: false')
              return false # here we have tongs in hand, as tongs, but they're not adjustable, so this returns false.
            when 'You lock the tongs' # now in shovel, adjust success but in wrong configuration
              DRC.bput("adjust my tongs", 'With a yank you fold the shovel') # now tongs, ready to work
              @tongs_status = 'tongs'
              return true # tongs as tongs AND adjustable
            when 'With a yank you fold the shovel' # now tongs
              @tongs_status = 'tongs'
              return true # tongs as tongs AND adjustable
            end
          end

        when 'reset shovel', 'reset tongs' # Used at the top of a script, to determine state of tongs.
          @tongs_status = nil
          adjustable_tongs = true
          if usage == 'reset shovel'
            return DRCC.get_adjust_tongs?('shovel', bag, bag_items, belt, adjustable_tongs)
          elsif usage == 'reset tongs'
            return DRCC.get_adjust_tongs?('tongs', bag, bag_items, belt, adjustable_tongs)
          end
        end
      end

      # Logs an item in the specified logbook.
      # @param logbook [String] The name of the logbook to use.
      # @param noun [String] The noun to log.
      # @param container [String] The container to put the logbook in.
      # @return [void]
      # @example
      #   logbook_item("crafting", "metal pike", "backpack")
      def logbook_item(logbook, noun, container)
        DRC.bput("get my #{logbook} logbook", 'You get')
        case DRC.bput("bundle my #{noun} with my logbook", 'You notate the', 'This work order has expired', 'The work order requires items of a higher quality', 'That isn\'t the correct type of item for this work order.')
        when 'This work order has expired', 'The work order requires items of a higher quality', 'That isn\'t the correct type of item for this work order.'
          DRCI.dispose_trash(noun)
        end
        case DRC.bput("put my #{logbook} logbook in my #{container}", 'You tuck', 'You put', 'What were you referring to')
        when 'What were you referring to'
          DRC.bput("stow my #{logbook} logbook", 'You put', 'What were you referring to')
        end
      end

      # Orders the specified amount of stock for enchanting.
      # @param stock_room [String] The room to order stock from.
      # @param stock_needed [Integer] The number of stocks needed.
      # @param stock_number [Integer] The stock number to order.
      # @param bag [String] The name of the bag to stow items in.
      # @param belt [Hash] The belt containing items.
      # @return [void]
      # @example
      #   order_enchant("stock-room", 5, 123, "backpack", belt)
      def order_enchant(stock_room, stock_needed, stock_number, bag, belt)
        stock_needed.times do
          DRCT.order_item(stock_room, stock_number)
          stow_crafting_item(DRC.left_hand, bag, belt)
          stow_crafting_item(DRC.right_hand, bag, belt)
          next unless DRC.left_hand && DRC.right_hand
        end
      end

      # Manages the fount for enchanting stock.
      # @param stock_room [String] The room to manage the fount in.
      # @param stock_needed [Integer] The number of stocks needed.
      # @param stock_number [Integer] The stock number to manage.
      # @param quantity [Integer] The quantity to manage.
      # @param bag [String] The name of the bag to stow items in.
      # @param bag_items [Array<String>] The list of items in the bag.
      # @param belt [Hash] The belt containing items.
      # @return [void]
      # @example
      #   fount("stock-room", 5, 123, 10, "backpack", bag_items, belt)
      def fount(stock_room, stock_needed, stock_number, quantity, bag, bag_items, belt)
        case DRC.bput('tap my fount', /You tap .* inside your .*/, /You tap .*your .*/, /I could not find what you were referring to./)
        when /You tap (.*) inside your (.*)/, /You tap (.*) your (.*)/
          /(\d+)/ =~ DRC.bput('analyze my fount', 'This appears to be a crafting tool and it has approximately \d+ uses remaining')
          if Regexp.last_match(1).to_i < (quantity + 1)
            get_crafting_item('fount', bag, bag_items, belt)
            DRCT.dispose('fount')
            DRCI.stow_hands
            order_enchant(stock_room, stock_needed, stock_number, bag, belt)
          end
        when /I could not find what you were referring to./
          case DRC.bput('tap my fount on my brazier', /You tap .* atop a .*brazier./, /I could not find what you were referring to./)
          when /You tap (.*) atop a (.*)brazier./
            /(\d+)/ =~ DRC.bput('analyze my fount on my brazier', 'This appears to be a crafting tool and it has approximately \d+ uses remaining')
            if Regexp.last_match(1).to_i < quantity
              DRCI.stow_hands
              order_enchant(stock_room, stock_needed, stock_number, bag, belt)
            end
          when /I could not find what you were referring to./
            order_enchant(stock_room, stock_needed, stock_number, bag, belt)
          end
        end
      end

      # Checks if the brazier is clean.
      # @return [Boolean] true if the brazier is clean, false otherwise
      # @example
      #   if clean_brazier?
      #     puts "The brazier is clean."
      #   end
      def clean_brazier?
        case DRC.bput('look on brazier', 'There is nothing on there', "On the .* you see")
        when /There is nothing on there/i
          true
        when /On the .* you see/
          case DRC.bput("clean brazier", 'You prepare to clean off the brazier', 'There is nothing', 'The brazier is not currently lit')
          when 'You prepare to clean off the brazier'
            DRC.bput("clean brazier", 'a massive ball of flame jets forward and singes everything nearby')
          end
          empty_brazier
          true
        end
      end

      # Empties the brazier of items.
      # @return [void]
      # @example
      #   empty_brazier
      def empty_brazier
        case DRC.bput("look on brazier", /On the (.*)brazier you see (.*)./, 'There is nothing')
        when /On the (.*)brazier you see (.*)./
          items = Regexp.last_match(2)
          items = items.split(' and ')
          items.each do |item|
            item = item.split.last
            DRC.bput("get #{item} from brazier", 'You get')
            DRCT.dispose(item)
          end
        end
      end

      # Checks for existing sigils and orders more if necessary.
      # @param sigil [String] The type of sigil to check for.
      # @param stock_number [Integer] The stock number for ordering.
      # @param quantity [Integer] The quantity needed.
      # @param bag [String] The name of the bag to stow items in.
      # @param belt [Hash] The belt containing items.
      # @param info [Hash] Additional information for ordering.
      # @return [Boolean] true if sigils are sufficient, false otherwise.
      # @example
      #   sufficient = check_for_existing_sigil?("fire", 123, 5, "backpack", belt, info)
      def check_for_existing_sigil?(sigil, stock_number, quantity, bag, belt, info)
        merged = Regexp.union($PRIMARY_SIGILS_PATTERN, $SECONDARY_SIGILS_PATTERN)

        more = 0
        tmp_count = DRCI.count_items_in_container("#{sigil} sigil-scroll", bag).to_i

        if tmp_count >= quantity
          return true
        else
          if merged.match?("#{sigil} sigil")
            more = quantity - tmp_count
            # Found a weird challenge that made the temp_part_count equal 1 even though no "sigil" was in container
            more += 1 if reget(3, "but there is nothing in there like that")
            DRCC.order_enchant(info['stock-room'], more, stock_number, bag, belt)
            return true
          else
            DRC.message("Not enough #{sigil} sigil-scroll(s). You can purchase or harvest #{more} more. We recommend using our sigilhunter script. Run #{$clean_lich_char}sigilhunter help for more information.")
            return false
          end
        end
      end

      # Counts the amount of raw metal in a specified container.
      # @param container [String] The name of the container to search in.
      # @param type [String, nil] Optional type of metal to count.
      # @return [Hash, nil] A hash of metal types and their counts or nil if not found.
      # @example
      #   metals = count_raw_metal("backpack")
      def count_raw_metal(container, type = nil)
        case DRC.bput("rummage /M #{container}", /crafting materials but there is nothing in there like that\.$/, /While it\'s closed/, /I don\'t know what you are referring to/, /You feel about/, /That would accomplish nothing/, /looking for crafting materials and see (.*)\.$/)
        when /crafting materials but there is nothing in there like that\.$/
          DRC.message("No materials found")
          return
        when /While it\'s closed/
          return unless DRCI.open_container?(container)

          count_raw_metal(container, type)
        when /I don\'t know what you are referring to/
          DRC.message("Container not found.")
          return
        when /You feel about/
          DRC.message("Try again when you're not invisible.")
          return
        when /looking for crafting materials and see (.*)\.$/
          h = Hash.new
          list = Regexp.last_match(1).sub(' and ', ', ').split(', ')
          list.each do |e|
            metal = e.split[2]
            volume = $VOL_MAP[e.split[1]]
            if h.key?(metal)
              h[metal][0] += volume
              h[metal][1] += 1
            else
              h[metal] = [volume, 1]
            end
          end
          h.each do |k, v|
            DRC.message("#{k} - #{v[0]} volume - #{v[1]} pieces")
          end
        else
          DRC.message("Please report this error to the dev team on discord.  Include a log snippet if possible.")
          return
        end
        type.nil? ? (return h) : (return h[type])
      end
    end
  end
end
