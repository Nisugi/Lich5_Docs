module Lich
  # module Gemstone # test this?
  # Provides functionality for claiming rooms in the game.
  # This module manages the state of claimed rooms and handles related operations.
  # @example Claiming a room
  #   Claim.claim_room(123)
  module Claim
    # Mutex for synchronizing access to claimed room data.
    Lock            = Mutex.new
    @claimed_room ||= nil
    @last_room    ||= nil
    @mine         ||= false
    @buffer         = []
    @others         = []
    @timestamp      = Time.now

    # Claims a room with the given ID.
    # @param id [Integer] The ID of the room to claim.
    # @return [void]
    # @raise [StandardError] If there is an issue claiming the room.
    # @example Claiming a room
    #   Claim.claim_room(123)
    def self.claim_room(id)
      @claimed_room = id.to_i
      @timestamp    = Time.now
      Log.out("claimed #{@claimed_room}", label: %i(claim room)) if defined?(Log)
      Lock.unlock
    end

    # Returns the ID of the currently claimed room.
    # @return [Integer, nil] The ID of the claimed room or nil if none is claimed.
    def self.claimed_room
      @claimed_room
    end

    # Returns the ID of the last room that was checked.
    # @return [Integer, nil] The ID of the last room checked or nil if none.
    def self.last_room
      @last_room
    end

    # Acquires the lock for the claiming process if not already owned.
    # @return [void]
    def self.lock
      Lock.lock if !Lock.owned?
    end

    # Releases the lock for the claiming process if owned.
    # @return [void]
    def self.unlock
      Lock.unlock if Lock.owned?
    end

    # Checks if the current instance is the one that claimed the room.
    # @return [Boolean] True if this instance is the owner of the claimed room, false otherwise.
    def self.current?
      Lock.synchronize { @mine.eql?(true) }
    end

    # Checks if the specified room has been checked.
    # @param room [Integer, nil] The room ID to check; defaults to the last room if nil.
    # @return [Boolean] True if the room has been checked, false otherwise.
    def self.checked?(room = nil)
      Lock.synchronize { XMLData.room_id == (room || @last_room) }
    end

    # Provides information about the current claim status and related data.
    # @return [String] A formatted string containing the claim information.
    # @example Displaying claim info
    #   puts Claim.info
    def self.info
      rows = [['XMLData.room_id', XMLData.room_id, 'Current room according to the XMLData'],
              ['Claim.mine?', Claim.mine?, 'Claim status on the current room'],
              ['Claim.claimed_room', Claim.claimed_room, 'Room id of the last claimed room'],
              ['Claim.checked?', Claim.checked?, "Has Claim finished parsing ROOMID\ndefault: the current room"],
              ['Claim.last_room', Claim.last_room, 'The last room checked by Claim, regardless of status'],
              ['Claim.others', Claim.others.join("\n"), "Other characters in the room\npotentially less grouped characters"]]
      info_table = Terminal::Table.new :headings => ['Property', 'Value', 'Description'],
                                       :rows     => rows,
                                       :style    => { :all_separators => true }
      Lich::Messaging.mono(info_table.to_s)
    end

    # Checks if the current instance is the owner of the claimed room.
    # @return [Boolean] True if this instance owns the claimed room, false otherwise.
    def self.mine?
      self.current?
    end

    # Returns a list of other characters in the room.
    # @return [Array<String>] An array of character names present in the room.
    def self.others
      @others
    end

    # Returns a list of members in the group if defined.
    # @return [Array<String>] An array of member nouns or an empty array if not applicable.
    def self.members
      return [] unless defined? Group

      begin
        if Group.checked?
          return Group.members.map(&:noun)
        else
          return []
        end
      rescue
        return []
      end
    end

    # Returns a list of connected clusters if defined.
    # @return [Array] An array of connected clusters or an empty array if not applicable.
    def self.clustered
      begin
        return [] unless defined? Cluster
        Cluster.connected
      rescue
        return []
      end
    end

    # Handles the parsing of room claims and updates the state accordingly.
    # @param nav_rm [Integer] The room ID being navigated to.
    # @param pcs [Array<String>] The list of character names present in the room.
    # @return [void]
    # @raise [StandardError] If there is an error during parsing.
    # @example Handling a room claim
    #   Claim.parser_handle(123, ['Alice', 'Bob'])
    def self.parser_handle(nav_rm, pcs)
      echo "Claim handled #{nav_rm} with xmlparser" if $claim_debug
      begin
        @others = pcs - self.clustered - self.members
        @last_room = nav_rm
        unless @others.empty?
          @mine = false
          return
        end
        @mine = true
        self.claim_room nav_rm unless nav_rm.nil?
      rescue StandardError => e
        if defined?(Log)
          Log.out(e)
        else
          respond("Claim Parser Error: #{e}")
        end
      ensure
        Lock.unlock if Lock.owned?
      end
    end
  end
  # end
end
