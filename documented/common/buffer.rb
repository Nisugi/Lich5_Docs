# Carve out module Buffer
# 2024-06-13
# has rubocop error Lint/HashCompareByIdentity - cop disabled until reviewed

module Lich
  # Provides common functionality for the Lich project.
  # @example Including the Common module
  #   include Lich::Common
  module Common
    # Manages a buffer for handling streams in a thread-safe manner.
    # @example Using the Buffer module
    #   Lich::Common::Buffer.update(line)
    #   Lich::Common::Buffer.gets
    module Buffer
      # Constant representing the stripped downstream stream.
      DOWNSTREAM_STRIPPED = 1
      # Constant representing the raw downstream stream.
      DOWNSTREAM_RAW      = 2
      # Constant representing the modified downstream stream.
      DOWNSTREAM_MOD      = 4
      # Constant representing the upstream stream.
      UPSTREAM            = 8
      # Constant representing the modified upstream stream.
      UPSTREAM_MOD        = 16
      # Constant representing the script output stream.
      SCRIPT_OUTPUT       = 32
      @@index             = Hash.new
      @@streams           = Hash.new
      @@mutex             = Mutex.new
      @@offset            = 0
      @@buffer            = Array.new
      @@max_size          = 3000
      # Retrieves the next line from the buffer in a thread-safe manner.
      # @return [Line] The next line from the buffer.
      # @note This method blocks until a line is available.
      def Buffer.gets
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        line = nil
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            sleep 0.05 while ((@@index[thread_id] - @@offset) >= @@buffer.length)
          end
          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          break if ((line.stream & @@streams[thread_id]) != 0)
        }
        return line
      end

      # Retrieves the next line from the buffer if available, non-blocking.
      # @return [Line, nil] The next line from the buffer or nil if none is available.
      def Buffer.gets?
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        line = nil
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            return nil
          end

          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          break if ((line.stream & @@streams[thread_id]) != 0)
        }
        return line
      end

      # Resets the buffer index for the current thread.
      # @return [Buffer] The Buffer instance for method chaining.
      def Buffer.rewind
        thread_id = Thread.current.object_id
        @@index[thread_id] = @@offset
        @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
        return self
      end

      # Clears the buffer for the current thread and returns all lines.
      # @return [Array<Line>] An array of lines that were in the buffer.
      def Buffer.clear
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        lines = Array.new
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            return lines
          end

          line = nil
          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          lines.push(line) if ((line.stream & @@streams[thread_id]) != 0)
        }
        return lines
      end

      # Updates the buffer with a new line, managing the buffer size.
      # @param line [Line] The line to add to the buffer.
      # @param stream [Integer, nil] Optional stream identifier.
      # @return [Buffer] The Buffer instance for method chaining.
      def Buffer.update(line, stream = nil)
        @@mutex.synchronize {
          frozen_line = line.dup
          unless stream.nil?
            frozen_line.stream = stream
          end
          frozen_line.freeze
          @@buffer.push(frozen_line)
          while (@@buffer.length > @@max_size)
            @@buffer.shift
            @@offset += 1
          end
        }
        return self
      end

      # rubocop:disable Lint/HashCompareByIdentity
      # Retrieves the current stream for the calling thread.
      # @return [Integer] The current stream identifier.
      def Buffer.streams
        @@streams[Thread.current.object_id]
      end

      # Sets the stream for the calling thread.
      # @param val [Integer] The stream identifier to set.
      # @return [nil] Returns nil if the value is invalid.
      def Buffer.streams=(val)
        if (!val.is_a?(Integer)) or ((val & 63) == 0)
          respond "--- Lich: error: invalid streams value\n\t#{$!.caller[0..2].join("\n\t")}"
          return nil
        end
        @@streams[Thread.current.object_id] = val
      end

      # rubocop:enable Lint/HashCompareByIdentity
      # Cleans up the buffer by removing entries for threads that no longer exist.
      # @return [Buffer] The Buffer instance for method chaining.
      def Buffer.cleanup
        @@index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        @@streams.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
