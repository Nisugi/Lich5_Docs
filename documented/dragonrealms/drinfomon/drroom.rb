module Lich
  module DragonRealms
    # Represents a room in the DragonRealms game.
    # This class manages the state of the room, including NPCs, PCs, and room properties.
    # @example Accessing room properties
    #   room = Lich::DragonRealms::DRRoom
    #   room.title = "A Dark Cave"
    #   puts room.description
    class DRRoom
      @@npcs ||= []
      @@pcs ||= []
      @@group_members ||= []
      @@pcs_prone ||= []
      @@pcs_sitting ||= []
      @@dead_npcs ||= []
      @@room_objs ||= []
      @@exits ||= []
      @@title = ''
      @@description = ''

      # Returns the list of NPCs in the room.
      # @return [Array] An array of NPCs.
      def self.npcs
        @@npcs
      end

      # Sets the list of NPCs in the room.
      # @param val [Array] An array of NPCs to set.
      # @return [Array] The updated list of NPCs.
      # @example Setting NPCs
      #   Lich::DragonRealms::DRRoom.npcs = [npc1, npc2]
      def self.npcs=(val)
        @@npcs = val
      end

      # Returns the list of player characters (PCs) in the room.
      # @return [Array] An array of PCs.
      def self.pcs
        @@pcs
      end

      # Sets the list of player characters (PCs) in the room.
      # @param val [Array] An array of PCs to set.
      # @return [Array] The updated list of PCs.
      # @example Setting PCs
      #   Lich::DragonRealms::DRRoom.pcs = [pc1, pc2]
      def self.pcs=(val)
        @@pcs = val
      end

      # Returns the exits available in the room.
      # @return [Array] An array of exits.
      def self.exits
        XMLData.room_exits
      end

      # Returns the title of the room.
      # @return [String] The title of the room.
      def self.title
        XMLData.room_title
      end

      # Returns the description of the room.
      # @return [String] The description of the room.
      def self.description
        XMLData.room_description
      end

      # Returns the list of group members in the room.
      # @return [Array] An array of group members.
      def self.group_members
        @@group_members
      end

      # Sets the list of group members in the room.
      # @param val [Array] An array of group members to set.
      # @return [Array] The updated list of group members.
      # @example Setting group members
      #   Lich::DragonRealms::DRRoom.group_members = [member1, member2]
      def self.group_members=(val)
        @@group_members = val
      end

      # Returns the list of PCs that are prone in the room.
      # @return [Array] An array of prone PCs.
      def self.pcs_prone
        @@pcs_prone
      end

      # Sets the list of PCs that are prone in the room.
      # @param val [Array] An array of prone PCs to set.
      # @return [Array] The updated list of prone PCs.
      def self.pcs_prone=(val)
        @@pcs_prone = val
      end

      # Returns the list of PCs that are sitting in the room.
      # @return [Array] An array of sitting PCs.
      def self.pcs_sitting
        @@pcs_sitting
      end

      # Sets the list of PCs that are sitting in the room.
      # @param val [Array] An array of sitting PCs to set.
      # @return [Array] The updated list of sitting PCs.
      def self.pcs_sitting=(val)
        @@pcs_sitting = val
      end

      # Returns the list of dead NPCs in the room.
      # @return [Array] An array of dead NPCs.
      def self.dead_npcs
        @@dead_npcs
      end

      # Sets the list of dead NPCs in the room.
      # @param val [Array] An array of dead NPCs to set.
      # @return [Array] The updated list of dead NPCs.
      def self.dead_npcs=(val)
        @@dead_npcs = val
      end

      # Returns the list of objects in the room.
      # @return [Array] An array of room objects.
      def self.room_objs
        @@room_objs
      end

      # Sets the list of objects in the room.
      # @param val [Array] An array of room objects to set.
      # @return [Array] The updated list of room objects.
      def self.room_objs=(val)
        @@room_objs = val
      end
    end
  end
end
