# frozen_string_literal: true

module Lich
  module Gemstone
    # Gift class for tracking gift box status
    # Gift class for tracking gift box status
    #
    # This class manages the state of a gift box, including tracking the start time,
    # pulse count, and calculating remaining time.
    # @example Initializing a gift
    #   Lich::Gemstone::Gift.init_gift
    class Gift
      class << self
        attr_reader :gift_start, :pulse_count

        # Initializes the gift tracking system.
        # @return [void]
        # @example Initializing the gift system
        #   Lich::Gemstone::Gift.init_gift
        def init_gift
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Starts the gift tracking by resetting the start time and pulse count.
        # @return [void]
        # @example Starting the gift tracking
        #   Lich::Gemstone::Gift.started
        def started
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Increments the pulse count by one.
        # @return [void]
        # @example Incrementing the pulse count
        #   Lich::Gemstone::Gift.pulse
        def pulse
          @pulse_count += 1
        end

        # Calculates the remaining time in seconds based on the pulse count.
        # @return [Float] The remaining time in seconds.
        # @example Getting remaining time
        #   remaining_time = Lich::Gemstone::Gift.remaining
        def remaining
          ([360 - @pulse_count, 0].max * 60).to_f
        end

        # Calculates the time when the gift will restart.
        # @return [Time] The time when the gift restarts.
        # @example Getting restart time
        #   restart_time = Lich::Gemstone::Gift.restarts_on
        def restarts_on
          @gift_start + 594000
        end

        # Serializes the current state of the gift.
        # @return [Array] An array containing the gift start time and pulse count.
        # @example Serializing the gift state
        #   serialized_data = Lich::Gemstone::Gift.serialize
        def serialize
          [@gift_start, @pulse_count]
        end

        # Loads the serialized state of the gift from an array.
        # @param array [Array] An array containing the gift start time and pulse count.
        # @return [void]
        # @example Loading serialized data
        #   Lich::Gemstone::Gift.load_serialized = [Time.now, 5]
        def load_serialized=(array)
          @gift_start = array[0]
          @pulse_count = array[1].to_i
        end

        # Marks the gift as ended by setting the pulse count to 360.
        # @return [void]
        # @example Ending the gift tracking
        #   Lich::Gemstone::Gift.ended
        def ended
          @pulse_count = 360
        end

        # Placeholder method for stopwatch functionality.
        # @return [nil] This method currently does nothing.
        # @example Using the stopwatch method
        #   Lich::Gemstone::Gift.stopwatch
        def stopwatch
          nil
        end
      end

      # Initialize the class
      init_gift
    end
  end
end
