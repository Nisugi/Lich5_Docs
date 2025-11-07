# Carve out from lich.rbw
# class LimitedArray 2024-06-13

module Lich
  module Common
    # Represents an array with a limited maximum size.
    # This class extends the standard Array class to enforce a maximum size.
    # When the limit is reached, the oldest elements are removed.
    # @example Creating a LimitedArray
    #   limited_array = Lich::Common::LimitedArray.new(5)
    class LimitedArray < Array
      attr_accessor :max_size

      # Initializes a new LimitedArray with a specified size and an optional object.
      # @param size [Integer] The initial size of the array (default is 0).
      # @param obj [Object] An optional object to initialize the array with.
      # @return [LimitedArray] The newly created LimitedArray.
      def initialize(size = 0, obj = nil)
        @max_size = 200
        super
      end

      # Adds an element to the end of the array, removing the oldest elements if the maximum size is exceeded.
      # @param line [Object] The element to add to the array.
      # @return [Object] The element that was added to the array.
      # @note This method modifies the array in place.
      # @example Adding an element to the LimitedArray
      #   limited_array.push("new element")
      def push(line)
        self.shift while self.length >= @max_size
        super
      end

      # Adds an element to the end of the array, same as push.
      # @param line [Object] The element to add to the array.
      # @return [Object] The element that was added to the array.
      # @example Shoving an element into the LimitedArray
      #   limited_array.shove("another element")
      def shove(line)
        push(line)
      end

      # Returns an empty array representing the history.
      # @return [Array] An empty array.
      # @example Getting the history of the LimitedArray
      #   history = limited_array.history
      def history
        Array.new
      end
    end
  end
end
