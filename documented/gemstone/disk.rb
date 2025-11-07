module Lich
  module Gemstone
    # Represents a disk object in the game.
    # This class provides methods to identify, find, and manage disk objects.
    # @example Finding a disk by name
    #   disk = Disk.find_by_name("golden disk")
    class Disk
      # A list of nouns that represent different types of disks.
      NOUNS = %w{cassone chest coffer coffin coffret disk hamper saucer sphere trunk tureen}

      # Checks if the given object is a disk based on its name.
      # @param thing [Object] The object to check.
      # @return [Boolean] Returns true if the object is a disk, false otherwise.
      # @example
      #   Disk.is_disk?(some_object)
      #   # => true or false
      def self.is_disk?(thing)
        thing.name =~ /\b([A-Z][a-z]+) #{Regexp.union(NOUNS)}\b/
      end

      # Finds a disk by its name in the game's loot.
      # @param name [String] The name of the disk to find.
      # @return [Disk, nil] Returns a Disk object if found, nil otherwise.
      # @example
      #   disk = Disk.find_by_name("golden disk")
      #   # => #<Disk:0x00007f...>
      # @note This method searches through the game's loot.
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Mines the disk associated with the current character.
      # @return [Disk, nil] Returns the Disk object for the character, nil if not found.
      # @example
      #   disk = Disk.mine()
      #   # => #<Disk:0x00007f...>
      def self.mine
        find_by_name(Char.name)
      end

      # Retrieves all disk objects from the game's loot.
      # @return [Array<Disk>] An array of Disk objects.
      # @example
      #   disks = Disk.all()
      #   # => [#<Disk:0x00007f...>, #<Disk:0x00007f...>]
      def self.all()
        (GameObj.loot || []).select do |item|
          is_disk?(item)
        end.map do |i|
          Disk.new(i)
        end
      end

      # Provides read access to the disk's ID and name.
      attr_reader :id, :name

      # Initializes a new Disk object with the given game object.
      # @param obj [Object] The game object representing the disk.
      # @return [Disk] A new Disk instance.
      # @example
      #   disk = Disk.new(game_object)
      #   # => #<Disk:0x00007f...>
      def initialize(obj)
        @id   = obj.id
        @name = obj.name.split(" ").find do |word|
          word[0].upcase.eql?(word[0])
        end
      end

      # Compares this disk with another disk for equality.
      # @param other [Object] The object to compare with.
      # @return [Boolean] Returns true if both disks are equal, false otherwise.
      # @example
      #   disk1 == disk2
      #   # => true or false
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Checks if this disk is equal to another disk.
      # @param other [Object] The object to compare with.
      # @return [Boolean] Returns true if both disks are equal, false otherwise.
      def eql?(other)
        self == other
      end

      # Handles calls to methods that are not defined in this class.
      # @param method [Symbol] The name of the method being called.
      # @param args [Array] The arguments passed to the method.
      # @return [Object] Returns the result of the method call on the underlying game object.
      # @example
      #   disk.some_method
      #   # => result of GameObj[@id].some_method
      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts this disk into a container object.
      # @return [Container, GameObj] Returns a Container object if defined, otherwise returns the GameObj.
      # @example
      #   container = disk.to_container()
      #   # => #<Container:0x00007f...> or #<GameObj:0x00007f...>
      def to_container
        if defined?(Container)
          Container.new(@id)
        else
          GameObj["#{@id}"]
        end
      end
    end
  end
end
