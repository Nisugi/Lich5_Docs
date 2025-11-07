# Lich module for DragonRealms functionality
# This module contains methods for interacting with merchants and managing items.
# @example Using the Lich module
#   Lich::DragonRealms::DRCT.sell_item(room, item)
module Lich
  module DragonRealms
    module DRCT
      # Provides module-level methods for the DRCT module.
      module_function

      # Visit a merchant and sell an item.
      # Usually to sell junk at pawn shops.
      # Visit a merchant and sell an item.
      # Usually to sell junk at pawn shops.
      # @param room [String] The room where the merchant is located.
      # @param item [String] The item to sell.
      # @return [Boolean] Returns true if the item was sold, false otherwise.
      # @raise [StandardError] Raises an error if the item is not in hands.
      # @example Selling an item
      #   result = sell_item("pawn shop", "old sword")
      def sell_item(room, item)
        return false unless DRCI.in_hands?(item)

        walk_to(room)

        success_patterns = [
          /hands? you \d+ (kronars|lirums|dokoras)/i
        ]

        failure_patterns = [
          /I need to examine the merchandise first/,
          /That's not worth anything/,
          /I only deal in pelts/,
          /There's folk around here that'd slit a throat for this/
        ]

        case DRC.bput("sell my #{item}", *success_patterns, *failure_patterns)
        when *success_patterns
          true
        when *failure_patterns
          false
        end
      end

      # Visit a merchant and buy an item by offering their asking price.
      # Usually for restocking ammunition or other misc items.
      # Visit a merchant and buy an item by offering their asking price.
      # Usually for restocking ammunition or other misc items.
      # @param room [String] The room where the merchant is located.
      # @param item [String] The item to buy.
      # @return [void] No return value.
      # @example Buying an item
      #   buy_item("market", "arrows")
      def buy_item(room, item)
        walk_to(room)

        # Amount to pay should be first capturing group.
        patterns = [/prepared to offer it to you for (.*) (?:kronar|lirum|dokora)s?/,
                    /Let me but ask the humble sum of (.*) coins/,
                    /it would be just (\d*) (?:kronar|lirum|dokora)s?/,
                    /for a (?:mere )?(\d*) (?:kronar|lirum|dokora)s?/,
                    /I can let that go for...(.*) (?:kronar|lirum|dokora)s?/,
                    /cost you (?:just )?(.*) (?:kronar|lirum|dokora)s?/,
                    /it may be yours for just (.*) (?:kronar|lirum|dokora)s?/,
                    /I'll give that to you for (.*) (?:kronar|lirum|dokora)s?/,
                    /I'll let you have it for (.*) (?:kronar|lirum|dokora)s?/i,
                    /I ask that you give (.*) copper (?:kronar|lirum|dokora)s?/,
                    /it'll be (.*) (?:kronar|lirum|dokora)s?/,
                    /the price of (.*) coins? is all I ask/,
                    /tis only (.*) (?:kronar|lirum|dokora)s?/,
                    /That will be (.*) copper (?:kronar|lirum|dokora)s? please/,
                    /That'll be (.*) copper (?:kronar|lirum|dokora)s?/,
                    /to you for (.*) (?:kronar|lirum|dokora)s?/,
                    /I ask (.*) copper (?:kronar|lirum|dokora)s or if you would prefer/,
                    /Cost you just (.*) (?:kronar|lirum|dokora)s?, okie dokie\?/i,
                    /It will cost just (.*) (?:kronar|lirum|dokora)s?/i,
                    /I would suggest (.*) (?:kronar|lirum|dokora)s?/i,
                    /to you for (.*) (?:kronar|lirum|dokora)s?/i,
                    /asking (.*) (?:kronar|lirum|dokora)s?/i,
                    'You decide to purchase',
                    'Buy what']

        match = DRC.bput("buy #{item}", *patterns)
        if match
          patterns.each { |p| break if p.match(match) }
        end
        amount = Regexp.last_match(1)

        fput("offer #{amount}") if amount
      end

      # Visit a merchant and ask for an item.
      # Usually this is for bundling ropes or gem pouches.
      # Visit a merchant and ask for an item.
      # Usually this is for bundling ropes or gem pouches.
      # @param room [String] The room where the merchant is located.
      # @param name [String] The name of the merchant.
      # @param item [String] The item to ask for.
      # @return [Boolean] Returns true if the item is received, false otherwise.
      # @example Asking for an item
      #   result = ask_for_item?("market", "merchant", "gem pouch")
      def ask_for_item?(room, name, item)
        walk_to(room)

        success_patterns = [
          /hands you/
        ]

        failure_patterns = [
          /does not seem to know anything about that/,
          /All I know about/,
          /To whom are you speaking/,
          /Usage: ASK/
        ]

        case DRC.bput("ask #{name} for #{item}", *success_patterns, *failure_patterns)
        when /hands you/
          true
        else
          false
        end
      end

      # Visit a merchant and order from a menu.
      # Visit a merchant and order from a menu.
      # @param room [String] The room where the merchant is located.
      # @param item_number [Integer] The number of the item to order.
      # @return [void] No return value.
      # @example Ordering an item
      #   order_item("tavern", 1)
      def order_item(room, item_number)
        walk_to(room)

        return if DRC.bput("order #{item_number}", 'Just order it again', 'you don\'t have enough coins') == 'you don\'t have enough coins'

        DRC.bput("order #{item_number}", 'takes some coins from you')
      end

      # Dispose of an item in a trash can or designated area.
      # @param item [String] The item to dispose of.
      # @param trash_room [String, nil] The room where the trash can is located.
      # @param worn_trashcan [String, nil] The trash can being worn.
      # @param worn_trashcan_verb [String, nil] The verb to use for disposing.
      # @return [void] No return value.
      # @example Disposing of an item
      #   dispose("old shoes", "trash room")
      def dispose(item, trash_room = nil, worn_trashcan = nil, worn_trashcan_verb = nil)
        return unless item

        DRCT.walk_to(trash_room) unless trash_room.nil?
        DRCI.dispose_trash(item, worn_trashcan, worn_trashcan_verb)
      end

      # Refill a lockpick container with a specified type of lockpick.
      # @param lockpick_type [String] The type of lockpick to refill.
      # @param hometown [String] The hometown where the locksmith is located.
      # @param container [String] The container to refill.
      # @param count [Integer] The number of lockpicks to buy.
      # @return [void] No return value.
      # @example Refilling a lockpick container
      #   refill_lockpick_container("basic", "town", "lockpick case", 5)
      def refill_lockpick_container(lockpick_type, hometown, container, count)
        return if count < 1

        room = get_data('town')[hometown]['locksmithing']['id']

        if room.nil?
          echo '***No locksmith location found for current Hometown! Skipping refilling!***'
          return
        end

        walk_to(room)
        if Room.current.id != room
          echo '***Could not reach locksmith location! Skipping refilling!***'
          return
        end

        count.times do
          buy_item(room, "#{lockpick_type} lockpick")
          case DRC.bput("put my lockpick on my #{container}", 'You put', 'different kinds of lockpicks on the same lockpick')
          when 'different kinds of lockpicks on the same lockpick'
            DRC.message('There is something wrong with your lockpick settings. Mixing types in a container is not allowed.')
            break
          end
        end

        # Be polite to Thieves, who need the room to be empty
        DRC.fix_standing
        move('out') if XMLData.room_exits.include?('out')
      end

      # Walk to a specified room.
      # @param target_room [String, Integer] The room to walk to, can be a name or ID.
      # @param restart_on_fail [Boolean] Whether to retry if the first attempt fails.
      # @return [Boolean] Returns true if successfully reached the room, false otherwise.
      # @example Walking to a room
      #   success = walk_to("market")
      def walk_to(target_room, restart_on_fail = true)
        target_room = tag_to_id(target_room) if target_room.is_a?(String) && target_room.count("a-zA-Z") > 0

        return false if target_room.nil?

        room_num = target_room.to_i
        return true if room_num == Room.current.id

        DRC.fix_standing

        if Room.current.id.nil?
          echo "In an unknown room, manually attempting to navigate to #{room_num}"
          rooms = Map.list.select { |room| room.description.include?(XMLData.room_description.strip) && room.title.include?(XMLData.room_title) }
          if rooms.empty? || rooms.length > 1
            echo 'failed to find a matching room'
            return false
          end
          room = rooms.first
          return true if room_num == room.id

          if room.wayto[room_num.to_s]
            move room.wayto[room_num.to_s]
            return room_num == room.id
          end
          path = Map.findpath(room, Map[room_num])
          way = room.wayto[path.first.to_s]
          if way.is_a?(StringProc)
            way.call
          else
            move way
          end
          return walk_to(room_num)
        end

        script_handle = start_script('go2', [room_num.to_s], force: true)

        timer = Time.now
        prev_room = XMLData.room_description + XMLData.room_title

        # Moved flag declaration from the start of the method to here
        # so that they only exist when needed and because the above code
        # has lots of 'return' statements that'd have to be refactored to
        # properly delete the flags at each method exit point.
        # I didn't want to tackle that endeavor in this change.
        Flags.add('travel-closed-shop', 'The door is locked up tightly for the night', 'You smash your nose', '^A servant (blocks|stops)')
        Flags.add('travel-engaged', 'You are engaged')

        while Script.running.include?(script_handle)
          # Shop closed, stop script and open door then restart
          if Flags['travel-closed-shop']
            Flags.reset('travel-closed-shop')
            kill_script(script_handle)
            if /You open/ !~ DRC.bput('open door', 'It is locked', 'You .+', 'What were')
              # You cannot get to where you want to go,
              # and no amount of retries will get you through the locked door.
              restart_on_fail = false
              break
            end
            timer = Time.now
            script_handle = start_script('go2', [room_num.to_s])
          end
          # You're engaged, stop script and retreat then restart
          if Flags['travel-engaged']
            Flags.reset('travel-engaged')
            kill_script(script_handle)
            DRC.retreat
            timer = Time.now
            script_handle = start_script('go2', [room_num.to_s])
          end
          # Something interferred with movement, stop script then restart
          if (Time.now - timer) > 90
            kill_script(script_handle)
            pause 0.5 while Script.running.include?(script_handle)
            break unless restart_on_fail

            timer = Time.now
            script_handle = start_script('go2', [room_num.to_s])
          end
          # If an escort script is running or we're making progress then update our timer so we don't timeout (see above)
          if Script.running?('escort') || Script.running?('bescort') || (XMLData.room_description + XMLData.room_title) != prev_room || XMLData.room_description =~ /The terrain constantly changes as you travel along on your journey/
            timer = Time.now
          end
          # Where did you come from, where did you go? Where did you come from, Cotten-Eye Joe?
          prev_room = XMLData.room_description + XMLData.room_title
          pause 0.5
        end

        # Delete flags, no longer needed at this point
        Flags.delete('travel-closed-shop')
        Flags.delete('travel-engaged')

        # Consider just returning this boolean and letting callers decide what to do on a failed move.
        if room_num != Room.current.id && restart_on_fail
          echo "Failed to navigate to room #{room_num}, attempting again"
          walk_to(room_num)
        end
        room_num == Room.current.id
      end

      # Convert a tag to a room ID.
      # @param target [String] The tag to convert.
      # @return [Integer] The ID of the room associated with the tag.
      # @raise [StandardError] Raises an error if no matching room is found.
      # @example Getting a room ID from a tag
      #   room_id = tag_to_id("tavern")
      def tag_to_id(target)
        start_room = Room.current.id
        target_list = Map.list.find_all { |room| room.tags.include?(target) }.collect { |room| room.id }

        if target_list.empty?
          DRC.message("No go2 targets matching #{target} found!")
          exit
        end

        if target_list.include?(start_room)
          echo "You're already here..."
          return start_room
        end
        _previous, shortest_distances = Room.current.dijkstra(target_list)
        target_list.delete_if { |room_id| shortest_distances[room_id].nil? }
        if target_list.empty?
          DRC.message("Couldn't find a path from here to any room with a #{target} tag")
          exit
        end

        target_id = target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }.first
        unless target_id and (destination = Map[target_id])
          DRC.message("Something went wrong!  Debug failed with #{target_id}, #{destination}, and #{target}")
          exit
        end
        target_id
      end

      # Retreat from a room, avoiding specified NPCs.
      # @param ignored_npcs [Array] An array of NPCs to ignore while retreating.
      # @return [void] No return value.
      # @example Retreating from a room
      #   retreat(["goblin"])
      def retreat(ignored_npcs = [])
        return if (DRRoom.npcs - ignored_npcs).empty?

        DRC.retreat(ignored_npcs)
      end

      # Find an empty room based on specified criteria.
      # @param search_rooms [Array] An array of room IDs to search.
      # @param idle_room [String] A room to go to if no empty room is found.
      # @param predicate [Proc, nil] A condition to check for suitability.
      # @param min_mana [Integer] Minimum mana required to consider a room.
      # @param strict_mana [Boolean] Whether to enforce the minimum mana strictly.
      # @param max_search_attempts [Integer] Maximum attempts to find an empty room.
      # @param priotize_buddies [Boolean] Whether to prioritize rooms with friends.
      # @return [Boolean] Returns true if an empty room is found, false otherwise.
      # @example Finding an empty room
      #   found = find_empty_room([1, 2, 3], "idle room")
      def find_empty_room(search_rooms, idle_room, predicate = nil, min_mana = 0, strict_mana = false, max_search_attempts = Float::INFINITY, priotize_buddies = false)
        search_attempt = 0
        check_mana = min_mana > 0
        rooms_searched = 0
        loop do
          search_attempt += 1
          echo("*** Search attempt #{search_attempt} of #{max_search_attempts} to find a suitable room. ***")
          found_empty = false
          search_rooms.each do |room_id|
            walk_to(room_id)
            pause 0.1 until room_id == Room.current.id

            rooms_searched += 1

            if priotize_buddies && (rooms_searched <= search_rooms.size)
              suitable_room = ((DRRoom.pcs & UserVars.friends).any? && (DRRoom.pcs & UserVars.hunting_nemesis).none?)
              if (rooms_searched == search_rooms.size && (DRRoom.pcs & UserVars.friends).empty? && (DRRoom.pcs & UserVars.hunting_nemesis).empty?)
                echo("*** Reached last room in list, and found no buddies. Retrying for empty room. ***")
                return find_empty_room(search_rooms, idle_room, predicate, min_mana, strict_mana, max_search_attempts, priotize_buddies = false)
              end
            else
              suitable_room = predicate ? predicate.call(search_attempt) : (DRRoom.pcs - DRRoom.group_members).empty?
            end
            if suitable_room && check_mana && !(DRStats.moon_mage? || DRStats.trader?)
              found_empty = true
              suitable_room = (DRCA.perc_mana >= min_mana)
            end
            return true if suitable_room
          end

          if found_empty && check_mana && !strict_mana
            check_mana = false
            echo '*** Empty rooms found, but not with the right mana. Going to use those anyway! ***'
            next
          end

          (check_mana = min_mana > 0) && !check_mana

          if idle_room && search_attempt < max_search_attempts
            idle_room = idle_room.sample if idle_room.is_a?(Array)
            walk_to(idle_room)
            wait_time = rand(20..40)
            echo "*** Failed to find an empty room, pausing #{wait_time} seconds ***"
            pause wait_time
          else
            echo '*** Failed to find an empty room, stopping the search ***'
            return false
          end
        end
      end

      # Sort a list of destinations based on distance from the current room.
      # @param target_list [Array] An array of room IDs to sort.
      # @return [Array] A sorted array of room IDs.
      # @example Sorting destinations
      #   sorted_rooms = sort_destinations([3, 1, 2])
      def sort_destinations(target_list)
        target_list = target_list.collect(&:to_i)
        _previous, shortest_distances = Map.dijkstra(Room.current.id)
        target_list.delete_if { |room_num| shortest_distances[room_num].nil? && room_num != Room.current.id }
        target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }
      end

      # Find an empty room from a sorted list of rooms.
      # @param search_rooms [Array] An array of room IDs to search.
      # @param idle_room [String] A room to go to if no empty room is found.
      # @param predicate [Proc, nil] A condition to check for suitability.
      # @return [Boolean] Returns true if an empty room is found, false otherwise.
      # @example Finding a sorted empty room
      #   found = find_sorted_empty_room([1, 2, 3], "idle room")
      def find_sorted_empty_room(search_rooms, idle_room, predicate = nil)
        sorted_rooms = sort_destinations(search_rooms)
        find_empty_room(sorted_rooms, idle_room, predicate)
      end

      # Calculate the time to travel from one room to another.
      # @param origin [Integer] The ID of the starting room.
      # @param destination [Integer] The ID of the destination room.
      # @return [Integer] The time taken to travel to the destination room.
      # @example Calculating time to a room
      #   time = time_to_room(1, 3)
      def time_to_room(origin, destination)
        _previous, shortest_paths = Map.dijkstra(origin, destination)
        shortest_paths[destination]
      end

      # Reverse a path of directions.
      # @param path [Array] An array of directions to reverse.
      # @return [Array] An array of reversed directions.
      # @raise [StandardError] Raises an error if a direction cannot be reversed.
      # @example Reversing a path
      #   reversed = reverse_path(["north", "east"])
      def reverse_path(path)
        dir_to_prev_dir = {
          'northeast' => 'southwest',
          'southwest' => 'northeast',
          'northwest' => 'southeast',
          'southeast' => 'northwest',
          'north'     => 'south',
          'south'     => 'north',
          'east'      => 'west',
          'west'      => 'east',
          'up'        => 'down',
          'down'      => 'up'
        }
        reverse_path = []
        path = path.reverse
        for i in 0..path.length - 1
          if dir_to_prev_dir[path[i]].nil?
            DRC.message("Error: No reverse direction found for #{path[i]}.  Please use the full direction, northeast instead of ne, check your spelling, and make sure the path parameter is an array.")
            exit
          end
          reverse_path.push(dir_to_prev_dir[path[i]])
        end
        return reverse_path
      end

      # Get the target ID for a specific target in a hometown.
      # @param hometown [String] The name of the hometown.
      # @param target [String] The target to find.
      # @return [Integer, nil] The ID of the target, or nil if not found.
      # @example Getting a target ID
      #   target_id = get_hometown_target_id("town", "blacksmith")
      def get_hometown_target_id(hometown, target)
        hometown_data = get_data('town')[hometown]
        target_id = hometown_data[target] && hometown_data[target]['id']
        # try twice with pause if failed the first time, because sometimes data doesn't get loaded correctly
        if !target_id
          echo("*** get_hometown_target_id failed first attempt for #{target} in #{hometown}. Trying again:") if $common_travel_debug
          pause 2
          hometown_data = get_data('town')[hometown]
          target_id = hometown_data[target] && hometown_data[target]['id']
          if !target_id
            echo("*** get_hometown_target_id failed second attempt for #{target} in #{hometown}.  Likely target doesn't exist") if $common_travel_debug
            target_id = nil
          else
            echo("*** get_hometown_target_id succeeded second attempt for #{target} in #{hometown}.") if $common_travel_debug
          end
        end
        echo("*** target_id = #{target_id}") if $common_travel_debug
        target_id
      end
    end
  end
end
