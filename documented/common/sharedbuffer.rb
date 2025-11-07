# Carve out class SharedBuffer
# 2024-06-13
# has rubocop Lint/HashCompareByIdentity errors that require research - temporarily disabled

module Lich
  module Common
    # A thread-safe buffer that allows multiple threads to read and write data.
    # This class manages a shared buffer with a maximum size and provides methods to read from and write to it.
    # @example Creating a shared buffer
    #   buffer = Lich::Common::SharedBuffer.new(max_size: 1000)
    class SharedBuffer
      attr_accessor :max_size

      # Initializes a new SharedBuffer instance.
      # @param args [Hash] Options for initializing the buffer.
      # @option args [Integer] :max_size The maximum size of the buffer (default is 500).
      # @return [SharedBuffer]
      def initialize(args = {})
        @buffer = Array.new
        @buffer_offset = 0
        @buffer_index = Hash.new
        @buffer_mutex = Mutex.new
        @max_size = args[:max_size] || 500
        # return self # rubocop does not like this - Lint/ReturnInVoidContext
      end

      # Retrieves the next line from the buffer, blocking if necessary.
      # @return [String, nil] The next line from the buffer or nil if no line is available.
      # @note This method blocks until a line is available.
      def gets
        thread_id = Thread.current.object_id
        if @buffer_index[thread_id].nil?
          @buffer_mutex.synchronize { @buffer_index[thread_id] = (@buffer_offset + @buffer.length) }
        end
        if (@buffer_index[thread_id] - @buffer_offset) >= @buffer.length
          sleep 0.05 while ((@buffer_index[thread_id] - @buffer_offset) >= @buffer.length)
        end
        line = nil
        @buffer_mutex.synchronize {
          if @buffer_index[thread_id] < @buffer_offset
            @buffer_index[thread_id] = @buffer_offset
          end
          line = @buffer[@buffer_index[thread_id] - @buffer_offset]
        }
        @buffer_index[thread_id] += 1
        return line
      end

      # Retrieves the next line from the buffer without blocking.
      # @return [String, nil] The next line from the buffer or nil if no line is available.
      def gets?
        thread_id = Thread.current.object_id
        if @buffer_index[thread_id].nil?
          @buffer_mutex.synchronize { @buffer_index[thread_id] = (@buffer_offset + @buffer.length) }
        end
        if (@buffer_index[thread_id] - @buffer_offset) >= @buffer.length
          return nil
        end

        line = nil
        @buffer_mutex.synchronize {
          if @buffer_index[thread_id] < @buffer_offset
            @buffer_index[thread_id] = @buffer_offset
          end
          line = @buffer[@buffer_index[thread_id] - @buffer_offset]
        }
        @buffer_index[thread_id] += 1
        return line
      end

      # Clears the lines that have been read from the buffer.
      # @return [Array<String>] An array of lines that were cleared from the buffer.
      def clear
        thread_id = Thread.current.object_id
        if @buffer_index[thread_id].nil?
          @buffer_mutex.synchronize { @buffer_index[thread_id] = (@buffer_offset + @buffer.length) }
          return Array.new
        end
        if (@buffer_index[thread_id] - @buffer_offset) >= @buffer.length
          return Array.new
        end

        lines = Array.new
        @buffer_mutex.synchronize {
          if @buffer_index[thread_id] < @buffer_offset
            @buffer_index[thread_id] = @buffer_offset
          end
          lines = @buffer[(@buffer_index[thread_id] - @buffer_offset)..-1]
          @buffer_index[thread_id] = (@buffer_offset + @buffer.length)
        }
        return lines
      end

      # rubocop:disable Lint/HashCompareByIdentity
      # Resets the buffer index for the current thread to the beginning of the buffer.
      # @return [SharedBuffer] The current instance of SharedBuffer.
      def rewind
        @buffer_index[Thread.current.object_id] = @buffer_offset
        return self
      end

      # rubocop:enable Lint/HashCompareByIdentity
      # Adds a new line to the buffer, managing the size of the buffer.
      # @param line [String] The line to be added to the buffer.
      # @return [SharedBuffer] The current instance of SharedBuffer.
      def update(line)
        @buffer_mutex.synchronize {
          fline = line.dup
          fline.freeze
          @buffer.push(fline)
          while (@buffer.length > @max_size)
            @buffer.shift
            @buffer_offset += 1
          end
        }
        return self
      end

      # Cleans up the buffer index for threads that are no longer active.
      # @return [SharedBuffer] The current instance of SharedBuffer.
      def cleanup_threads
        @buffer_index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
