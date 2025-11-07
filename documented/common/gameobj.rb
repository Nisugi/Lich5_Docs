module Lich
  module Common
    # Represents a game object in the Lich game system.
    # This class manages various attributes and behaviors of game objects.
    # @example Creating a game object
    #   obj = GameObj.new("1", "sword", "Sword of Destiny")
    class GameObj
      @@loot          = Array.new
      @@npcs          = Array.new
      @@npc_status    = Hash.new
      @@pcs           = Array.new
      @@pc_status     = Hash.new
      @@inv           = Array.new
      @@contents      = Hash.new
      @@right_hand    = nil
      @@left_hand     = nil
      @@room_desc     = Array.new
      @@fam_loot      = Array.new
      @@fam_npcs      = Array.new
      @@fam_pcs       = Array.new
      @@fam_room_desc = Array.new
      @@type_data     = Hash.new
      @@type_cache    = Hash.new
      @@sellable_data = Hash.new

      attr_reader :id
      attr_accessor :noun, :name, :before_name, :after_name

      # Initializes a new game object.
      # @param id [String] The object ID.
      # @param noun [String] The object noun.
      # @param name [String] The object name.
      # @param before [String, nil] Optional prefix for the name.
      # @param after [String, nil] Optional suffix for the name.
      # @return [GameObj] The newly created game object.
      def initialize(id, noun, name, before = nil, after = nil)
        @id = id
        @noun = noun
        @noun = 'lapis' if @noun == 'lapis lazuli'
        @noun = 'hammer' if @noun == "Hammer of Kai"
        @noun = 'ball' if @noun == "ball and chain" # DR item 'ball and chain' doesn't work.
        @noun = 'mother-of-pearl' if (@noun == 'pearl') and (@name =~ /mother\-of\-pearl/)
        @name = name
        @before_name = before
        @after_name = after
      end

      # Retrieves the type of the game object based on its name and noun.
      # @return [String, nil] A comma-separated string of types or nil if none found.
      # @example
      #   obj.type # => "weapon, magical"
      def type
        GameObj.load_data if @@type_data.empty?
        return @@type_cache[@name] if @@type_cache.key?(@name)
        list = @@type_data.keys.find_all { |t| (@name =~ @@type_data[t][:name] or @noun =~ @@type_data[t][:noun]) and (@@type_data[t][:exclude].nil? or @name !~ @@type_data[t][:exclude]) }
        if list.empty?
          return @@type_cache[@name] = nil
        else
          return @@type_cache[@name] = list.join(',')
        end
      end

      # Checks if the game object is of a specific type.
      # @param type_to_check [String] The type to check against.
      # @return [Boolean] True if the object is of the specified type, false otherwise.
      def type?(type_to_check)
        # handle nil types
        return self.type.to_s.split(',').any?(type_to_check)
      end

      # Retrieves the sellable status of the game object.
      # @return [String, nil] A comma-separated string of sellable types or nil if none found.
      def sellable
        GameObj.load_data if @@sellable_data.empty?
        list = @@sellable_data.keys.find_all { |t| (@name =~ @@sellable_data[t][:name] or @noun =~ @@sellable_data[t][:noun]) and (@@sellable_data[t][:exclude].nil? or @name !~ @@sellable_data[t][:exclude]) }
        if list.empty?
          nil
        else
          list.join(',')
        end
      end

      # Retrieves the current status of the game object.
      # @return [String, nil] The status of the object or 'gone' if not found.
      def status
        if @@npc_status.keys.include?(@id)
          @@npc_status[@id]
        elsif @@pc_status.keys.include?(@id)
          @@pc_status[@id]
        elsif @@loot.find { |obj| obj.id == @id } or @@inv.find { |obj| obj.id == @id } or @@room_desc.find { |obj| obj.id == @id } or @@fam_loot.find { |obj| obj.id == @id } or @@fam_npcs.find { |obj| obj.id == @id } or @@fam_pcs.find { |obj| obj.id == @id } or @@fam_room_desc.find { |obj| obj.id == @id } or (@@right_hand.id == @id) or (@@left_hand.id == @id) or @@contents.values.find { |list| list.find { |obj| obj.id == @id } }
          nil
        else
          'gone'
        end
      end

      # Sets the status of the game object.
      # @param val [String] The new status value.
      # @return [nil] Always returns nil.
      def status=(val)
        if @@npcs.any? { |npc| npc.id == @id }
          @@npc_status[@id] = val
        elsif @@pcs.any? { |pc| pc.id == @id }
          @@pc_status[@id] = val
        else
          nil
        end
      end

      # Returns a string representation of the game object.
      # @return [String] The noun of the game object.
      def to_s
        @noun
      end

      # Checks if the game object is empty.
      # @return [Boolean] Always returns false.
      def empty?
        false
      end

      # Retrieves the contents of the game object.
      # @return [Array] A duplicate of the contents array.
      def contents
        @@contents[@id].dup
      end

      # Retrieves a game object by ID, noun, or name.
      # @param val [String, Regexp] The identifier to search for.
      # @return [GameObj, nil] The found game object or nil if not found.
      # @raise [ArgumentError] If val is not a String or Regexp.
      def self.[](val)
        unless val.is_a?(String) || val.is_a?(Regexp)
          respond "--- Lich: error: GameObj[] passed with #{val.class} #{val} via caller: #{caller[0]}"
          respond "--- Lich: error: GameObj[] supports String or Regexp only"
          Lich.log "--- Lich: error: GameObj[] passed with #{val.class} #{val} via caller: #{caller[0]}\n\t"
          Lich.log "--- Lich: error: GameObj[] supports String or Regexp only\n\t"
          if val.is_a?(Integer)
            respond "--- Lich: error: GameObj[] converted Integer #{val} to String to continue"
            val = val.to_s
          else
            return
          end
        end
        if val.is_a?(String)
          if val =~ /^\-?[0-9]+$/ # ID lookup
            # excludes @@room_desc ID lookup due to minimal use case, but could be added in future if desired
            @@inv.find { |o| o.id == val } || @@loot.find { |o| o.id == val } || @@npcs.find { |o| o.id == val } || @@pcs.find { |o| o.id == val } || [@@right_hand, @@left_hand].find { |o| o.id == val } || @@room_desc.find { |o| o.id == val } || @@contents.values.flatten.find { |o| o.id == val }
          elsif val.split(' ').length == 1 # noun lookup
            @@inv.find { |o| o.noun == val } || @@loot.find { |o| o.noun == val } || @@npcs.find { |o| o.noun == val } || @@pcs.find { |o| o.noun == val } || [@@right_hand, @@left_hand].find { |o| o.noun == val } || @@room_desc.find { |o| o.noun == val }
          else # name lookup
            @@inv.find { |o| o.name == val } || @@loot.find { |o| o.name == val } || @@npcs.find { |o| o.name == val } || @@pcs.find { |o| o.name == val } || [@@right_hand, @@left_hand].find { |o| o.name == val } || @@room_desc.find { |o| o.name == val } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || [@@right_hand, @@left_hand].find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || [@@right_hand, @@left_hand].find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i }
          end
        elsif val.is_a?(Regexp) # name only lookup when passed a Regexp
          @@inv.find { |o| o.name =~ val } || @@loot.find { |o| o.name =~ val } || @@npcs.find { |o| o.name =~ val } || @@pcs.find { |o| o.name =~ val } || [@@right_hand, @@left_hand].find { |o| o.name =~ val } || @@room_desc.find { |o| o.name =~ val }
        end
      end

      def GameObj
        @noun
      end

      # Constructs the full name of the game object.
      # @return [String] The full name including before and after names.
      def full_name
        "#{@before_name}#{' ' unless @before_name.nil? or @before_name.empty?}#{name}#{' ' unless @after_name.nil? or @after_name.empty?}#{@after_name}"
      end

      # Creates a new NPC game object.
      # @param id [String] The NPC ID.
      # @param noun [String] The NPC noun.
      # @param name [String] The NPC name.
      # @param status [String, nil] Optional status for the NPC.
      # @return [GameObj] The newly created NPC object.
      def self.new_npc(id, noun, name, status = nil)
        obj = GameObj.new(id, noun, name)
        @@npcs.push(obj)
        @@npc_status[id] = status
        obj
      end

      # Creates a new loot game object.
      # @param id [String] The loot ID.
      # @param noun [String] The loot noun.
      # @param name [String] The loot name.
      # @return [GameObj] The newly created loot object.
      def self.new_loot(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@loot.push(obj)
        obj
      end

      # Creates a new player character game object.
      # @param id [String] The PC ID.
      # @param noun [String] The PC noun.
      # @param name [String] The PC name.
      # @param status [String, nil] Optional status for the PC.
      # @return [GameObj] The newly created PC object.
      def self.new_pc(id, noun, name, status = nil)
        obj = GameObj.new(id, noun, name)
        @@pcs.push(obj)
        @@pc_status[id] = status
        obj
      end

      # Creates a new inventory item game object.
      # @param id [String] The inventory item ID.
      # @param noun [String] The inventory item noun.
      # @param name [String] The inventory item name.
      # @param container [String, nil] Optional container ID.
      # @param before [String, nil] Optional prefix for the name.
      # @param after [String, nil] Optional suffix for the name.
      # @return [GameObj] The newly created inventory object.
      def self.new_inv(id, noun, name, container = nil, before = nil, after = nil)
        obj = GameObj.new(id, noun, name, before, after)
        if container
          @@contents[container].push(obj)
        else
          @@inv.push(obj)
        end
        obj
      end

      # Creates a new room description game object.
      # @param id [String] The room description ID.
      # @param noun [String] The room description noun.
      # @param name [String] The room description name.
      # @return [GameObj] The newly created room description object.
      def self.new_room_desc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@room_desc.push(obj)
        obj
      end

      # Creates a new family room description game object.
      # @param id [String] The family room description ID.
      # @param noun [String] The family room description noun.
      # @param name [String] The family room description name.
      # @return [GameObj] The newly created family room description object.
      def self.new_fam_room_desc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_room_desc.push(obj)
        obj
      end

      # Creates a new family loot game object.
      # @param id [String] The family loot ID.
      # @param noun [String] The family loot noun.
      # @param name [String] The family loot name.
      # @return [GameObj] The newly created family loot object.
      def self.new_fam_loot(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_loot.push(obj)
        obj
      end

      # Creates a new family NPC game object.
      # @param id [String] The family NPC ID.
      # @param noun [String] The family NPC noun.
      # @param name [String] The family NPC name.
      # @return [GameObj] The newly created family NPC object.
      def self.new_fam_npc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_npcs.push(obj)
        obj
      end

      # Creates a new family player character game object.
      # @param id [String] The family PC ID.
      # @param noun [String] The family PC noun.
      # @param name [String] The family PC name.
      # @return [GameObj] The newly created family PC object.
      def self.new_fam_pc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_pcs.push(obj)
        obj
      end

      # Creates a new right-hand game object.
      # @param id [String] The right-hand object ID.
      # @param noun [String] The right-hand object noun.
      # @param name [String] The right-hand object name.
      # @return [GameObj] The newly created right-hand object.
      def self.new_right_hand(id, noun, name)
        @@right_hand = GameObj.new(id, noun, name)
      end

      # Retrieves the current right-hand game object.
      # @return [GameObj] A duplicate of the right-hand object.
      def self.right_hand
        @@right_hand.dup
      end

      # Creates a new left-hand game object.
      # @param id [String] The left-hand object ID.
      # @param noun [String] The left-hand object noun.
      # @param name [String] The left-hand object name.
      # @return [GameObj] The newly created left-hand object.
      def self.new_left_hand(id, noun, name)
        @@left_hand = GameObj.new(id, noun, name)
      end

      # Retrieves the current left-hand game object.
      # @return [GameObj] A duplicate of the left-hand object.
      def self.left_hand
        @@left_hand.dup
      end

      # Clears all loot game objects.
      # @return [nil] Always returns nil.
      def self.clear_loot
        @@loot.clear
      end

      # Clears all NPC game objects and their statuses.
      # @return [nil] Always returns nil.
      def self.clear_npcs
        @@npcs.clear
        @@npc_status.clear
      end

      # Clears all player character game objects and their statuses.
      # @return [nil] Always returns nil.
      def self.clear_pcs
        @@pcs.clear
        @@pc_status.clear
      end

      # Clears all inventory game objects.
      # @return [nil] Always returns nil.
      def self.clear_inv
        @@inv.clear
      end

      # Clears all room description game objects.
      # @return [nil] Always returns nil.
      def self.clear_room_desc
        @@room_desc.clear
      end

      # Clears all family room description game objects.
      # @return [nil] Always returns nil.
      def self.clear_fam_room_desc
        @@fam_room_desc.clear
      end

      # Clears all family loot game objects.
      # @return [nil] Always returns nil.
      def self.clear_fam_loot
        @@fam_loot.clear
      end

      # Clears all family NPC game objects.
      # @return [nil] Always returns nil.
      def self.clear_fam_npcs
        @@fam_npcs.clear
      end

      # Clears all family player character game objects.
      # @return [nil] Always returns nil.
      def self.clear_fam_pcs
        @@fam_pcs.clear
      end

      # Retrieves all NPC game objects.
      # @return [Array, nil] A duplicate of the NPCs array or nil if empty.
      def self.npcs
        if @@npcs.empty?
          nil
        else
          @@npcs.dup
        end
      end

      # Retrieves all loot game objects.
      # @return [Array, nil] A duplicate of the loot array or nil if empty.
      def self.loot
        if @@loot.empty?
          nil
        else
          @@loot.dup
        end
      end

      # Retrieves all player character game objects.
      # @return [Array, nil] A duplicate of the PCs array or nil if empty.
      def self.pcs
        if @@pcs.empty?
          nil
        else
          @@pcs.dup
        end
      end

      # Retrieves all inventory game objects.
      # @return [Array, nil] A duplicate of the inventory array or nil if empty.
      def self.inv
        if @@inv.empty?
          nil
        else
          @@inv.dup
        end
      end

      # Retrieves all room description game objects.
      # @return [Array, nil] A duplicate of the room descriptions array or nil if empty.
      def self.room_desc
        if @@room_desc.empty?
          nil
        else
          @@room_desc.dup
        end
      end

      # Retrieves all family room description game objects.
      # @return [Array, nil] A duplicate of the family room descriptions array or nil if empty.
      def self.fam_room_desc
        if @@fam_room_desc.empty?
          nil
        else
          @@fam_room_desc.dup
        end
      end

      # Retrieves all family loot game objects.
      # @return [Array, nil] A duplicate of the family loot array or nil if empty.
      def self.fam_loot
        if @@fam_loot.empty?
          nil
        else
          @@fam_loot.dup
        end
      end

      # Retrieves all family NPC game objects.
      # @return [Array, nil] A duplicate of the family NPCs array or nil if empty.
      def self.fam_npcs
        if @@fam_npcs.empty?
          nil
        else
          @@fam_npcs.dup
        end
      end

      # Retrieves all family player character game objects.
      # @return [Array, nil] A duplicate of the family PCs array or nil if empty.
      def self.fam_pcs
        if @@fam_pcs.empty?
          nil
        else
          @@fam_pcs.dup
        end
      end

      # Clears the contents of a specified container.
      # @param container_id [String] The ID of the container to clear.
      # @return [nil] Always returns nil.
      def self.clear_container(container_id)
        @@contents[container_id] = Array.new
      end

      # Deletes a specified container from the contents.
      # @param container_id [String] The ID of the container to delete.
      # @return [nil] Always returns nil.
      def self.delete_container(container_id)
        @@contents.delete(container_id)
      end

      # Retrieves the current targets from the game.
      # @return [Array] An array of current target NPCs.
      def self.targets
        a = Array.new
        XMLData.current_target_ids.each { |id|
          if (npc = @@npcs.find { |n| n.id == id })
            next if (npc.status =~ /dead|gone/i)
            next if (npc.name =~ /^animated\b/i && npc.name !~ /^animated slush/i)
            next if (npc.noun =~ /^(?:arm|appendage|claw|limb|pincer|tentacle)s?$|^(?:palpus|palpi)$/i && npc.name !~ /(?:amaranthine|ghostly|grizzled|ancient) kraken tentacle/i)
            a.push(npc)
          end
        }
        a
      end

      # Retrieves the IDs of hidden targets.
      # @return [Array] An array of hidden target IDs.
      def self.hidden_targets
        a = Array.new
        XMLData.current_target_ids.each { |id|
          unless @@npcs.find { |n| n.id == id }
            a.push(id)
          end
        }
        a
      end

      # Retrieves the current target from the game.
      # @return [GameObj, nil] The current target object or nil if not found.
      def self.target
        return (@@npcs + @@pcs).find { |n| n.id == XMLData.current_target_id }
      end

      # Retrieves all dead NPCs.
      # @return [Array, nil] An array of dead NPCs or nil if none found.
      def self.dead
        dead_list = Array.new
        for obj in @@npcs
          dead_list.push(obj) if obj.status == "dead"
        end
        return nil if dead_list.empty?

        return dead_list
      end

      # Retrieves all containers in the game.
      # @return [Hash] A duplicate of the contents hash.
      def self.containers
        @@contents.dup
      end

      # Reloads the game object data from a file.
      # @param filename [String, nil] The name of the file to load.
      # @return [Boolean] True if the data was successfully reloaded, false otherwise.
      def self.reload(filename = nil)
        GameObj.load_data(filename)
      end

      # Merges two data sets, handling Regexp types.
      # @param data [Regexp, nil] The existing data.
      # @param newData [Regexp] The new data to merge.
      # @return [Regexp] The merged data.
      def self.merge_data(data, newData)
        return newData unless data.is_a?(Regexp)
        return Regexp.union(data, newData)
      end

      # Loads game object data from an XML file.
      # @param filename [String, nil] The name of the file to load.
      # @return [Boolean] True if the data was successfully loaded, false otherwise.
      def self.load_data(filename = nil)
        filename = File.join(DATA_DIR, 'gameobj-data.xml') if filename.nil?
        if File.exist?(filename)
          begin
            @@type_data = Hash.new
            @@sellable_data = Hash.new
            @@type_cache = Hash.new
            File.open(filename) { |file|
              doc = REXML::Document.new(file.read)
              doc.elements.each('data/type') { |e|
                if (type = e.attributes['name'])
                  @@type_data[type] = Hash.new
                  @@type_data[type][:name]    = Regexp.new(e.elements['name'].text) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@type_data[type][:noun]    = Regexp.new(e.elements['noun'].text) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@type_data[type][:exclude] = Regexp.new(e.elements['exclude'].text) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
              doc.elements.each('data/sellable') { |e|
                if (sellable = e.attributes['name'])
                  @@sellable_data[sellable] = Hash.new
                  @@sellable_data[sellable][:name]    = Regexp.new(e.elements['name'].text) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@sellable_data[sellable][:noun]    = Regexp.new(e.elements['noun'].text) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@sellable_data[sellable][:exclude] = Regexp.new(e.elements['exclude'].text) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
            }
          rescue
            @@type_data = nil
            @@sellable_data = nil
            echo "error: GameObj.load_data: #{$!}"
            respond $!.backtrace[0..1]
            return false
          end
        else
          @@type_data = nil
          @@sellable_data = nil
          echo "error: GameObj.load_data: file does not exist: #{filename}"
          return false
        end
        filename = File.join(DATA_DIR, 'gameobj-custom', 'gameobj-data.xml')
        if (File.exist?(filename))
          begin
            File.open(filename) { |file|
              doc = REXML::Document.new(file.read)
              doc.elements.each('data/type') { |e|
                if (type = e.attributes['name'])
                  @@type_data[type] ||= Hash.new
                  @@type_data[type][:name]	  = GameObj.merge_data(@@type_data[type][:name], Regexp.new(e.elements['name'].text)) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@type_data[type][:noun]	  = GameObj.merge_data(@@type_data[type][:noun], Regexp.new(e.elements['noun'].text)) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@type_data[type][:exclude] = GameObj.merge_data(@@type_data[type][:exclude], Regexp.new(e.elements['exclude'].text)) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
              doc.elements.each('data/sellable') { |e|
                if (sellable = e.attributes['name'])
                  @@sellable_data[sellable] ||= Hash.new
                  @@sellable_data[sellable][:name]	  = GameObj.merge_data(@@sellable_data[sellable][:name], Regexp.new(e.elements['name'].text)) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@sellable_data[sellable][:noun]	  = GameObj.merge_data(@@sellable_data[sellable][:noun], Regexp.new(e.elements['noun'].text)) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@sellable_data[sellable][:exclude] = GameObj.merge_data(@@sellable_data[sellable][:exclude], Regexp.new(e.elements['exclude'].text)) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
            }
          rescue
            echo "error: Custom GameObj.load_data: #{$!}"
            respond $!.backtrace[0..1]
            return false
          end
        end
        return true
      end

      # Retrieves the type data for game objects.
      # @return [Hash] The type data hash.
      def self.type_data
        @@type_data
      end

      # Retrieves the type cache for game objects.
      # @return [Hash] The type cache hash.
      def self.type_cache
        @@type_cache
      end

      # Retrieves the sellable data for game objects.
      # @return [Hash] The sellable data hash.
      def self.sellable_data
        @@sellable_data
      end
    end

    # start deprecated stuff
    # Represents a room object, inheriting from GameObj.
    # This class is deprecated and may be removed in future versions.
    class RoomObj < GameObj
    end
    # end deprecated stuff
  end
end
